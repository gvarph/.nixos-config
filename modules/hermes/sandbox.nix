{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.services.hermes-agent) stateDir;
  # No systemd user session for hermes, so podman would warn on every call (and
  # Hermes merges that into tool output, breaking its write verifier).
  podmanEnv = {
    XDG_RUNTIME_DIR = "/run/hermes";
    CONTAINERS_CONF_OVERRIDE = "${pkgs.writeText "hermes-containers.conf" ''
      [engine]
      cgroup_manager = "cgroupfs"
    ''}";
  };
  runtimeDir = {
    RuntimeDirectory = "hermes";
    RuntimeDirectoryMode = "0700";
    RuntimeDirectoryPreserve = true;
  };
  # Host paths the agent's sandbox may see, as "host:container[:ro]". Nothing
  # outside its own workspace is visible unless it is listed here.
  grants = [
    "/home/gvarph/.nixos-config/modules/hermes:/grants/nixos-config:ro"
  ];
  # Hermes reattaches to its old container, which keeps the mounts it was created with.
  volumesStamp = pkgs.writeText "hermes-sandbox-volumes" (lib.concatLines config.services.hermes-agent.settings.terminal.docker_volumes);
in {
  # Every shell / Python command the agent executes runs in a rootless podman
  # container (cap-drop ALL, no-new-privileges) that only sees /workspace plus `grants`.
  services.hermes-agent = {
    environment.HERMES_DOCKER_BINARY = "${pkgs.podman}/bin/podman";
    settings.terminal = {
      backend = "docker";
      cwd = "/workspace";
      docker_image = "docker.io/nousresearch/hermes-sandbox@sha256:725942c1d6aa17a76cdc5f7289c836e29563e99bf53f7c9f8b848d5c89d49f70";
      docker_volumes = ["${stateDir}/workspace:/workspace"] ++ grants;
      docker_network = true;
      container_cpu = 2;
      container_memory = 4096;
      container_disk = 20480;
      container_persistent = true;
    };
  };

  # Rootless podman for the sandbox: subordinate ids for the user namespace,
  # newuidmap from the setuid wrappers (hence NoNewPrivileges off for the
  # agent itself; the sandbox containers keep it on), and a runtime dir that
  # ProtectSystem=strict leaves writable.
  users.users.hermes.autoSubUidGidRange = true;

  # The nixos-config grant needs hermes to traverse ~gvarph. User activation
  # chmods homes to 700 on every switch, which zeroes the ACL mask, so re-apply.
  system.activationScripts.hermesGrantAcl = lib.stringAfter ["users"] ''
    ${pkgs.acl}/bin/setfacl -m user:hermes:x,mask::x /home/gvarph
    ${pkgs.acl}/bin/setfacl -m user:hermes:x /home/gvarph/.nixos-config
    ${pkgs.acl}/bin/setfacl -m user:hermes:rx,default:user:hermes:rx /home/gvarph/.nixos-config/modules/hermes
  '';

  systemd.services =
    {
      # Rootless podman joins the mount namespace of its long-lived "pause" process.
      # Created from inside a hardened unit (PrivateTmp etc.) that namespace goes
      # stale on restart (no /tmp, /var/tmp -> exit 127). This unprivileged unit
      # without private mounts creates it first, replacing any stale one.
      hermes-podman-pause = {
        description = "Rootless podman pause process for the Hermes sandbox";
        after = ["zfs-mount.service"];
        unitConfig.ConditionPathIsMountPoint = stateDir;
        path = [pkgs.podman "/run/wrappers" pkgs.coreutils pkgs.findutils];
        environment = podmanEnv // {HOME = stateDir;};
        serviceConfig =
          runtimeDir
          // {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "hermes";
            Group = "hermes";
            ExecStartPre = "-${pkgs.bash}/bin/sh -c 'kill $(cat /run/hermes/libpod/tmp/pause.pid) 2>/dev/null; true'";
            ExecStart = "${pkgs.podman}/bin/podman unshare true";
            # Grants changed: drop the sandbox so Hermes recreates it (/root and /workspace persist).
            ExecStartPost = pkgs.writeShellScript "hermes-sandbox-refresh" ''
              if [ "$(cat ${volumesStamp})" != "$(cat ${stateDir}/.sandbox-volumes 2>/dev/null)" ]; then
                podman ps -aq --filter label=hermes-agent=1 | xargs -r podman rm -f
                install -m 644 ${volumesStamp} ${stateDir}/.sandbox-volumes
              fi
            '';
          };
      };
    }
    // lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
      after = ["hermes-podman-pause.service"];
      requires = ["hermes-podman-pause.service"];
      path = [pkgs.podman "/run/wrappers"];
      environment = podmanEnv;
      serviceConfig =
        runtimeDir
        // {
          NoNewPrivileges = lib.mkForce false;
        };
    });
}
