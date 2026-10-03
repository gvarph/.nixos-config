{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/hermes";
  # Host paths the agent's sandbox may see, as "host:container[:ro]". Nothing
  # outside its own workspace is visible unless it is listed here.
  grants = [
    # "/tank/media/ebooks:/grants/ebooks:ro"
  ];
in {
  imports = [inputs.hermes-agent.nixosModules.default];

  # 9router API key as OPENAI_API_KEY (custom OpenAI-compatible provider).
  age.secrets.hermes_env = {
    file = ../../secrets/hermes_env.age;
    owner = "hermes";
  };

  # The agent runs natively as the unprivileged `hermes` user; every shell /
  # Python command it executes runs in a rootless podman container (cap-drop
  # ALL, no-new-privileges) that only sees /workspace plus `grants`.
  services.hermes-agent = {
    enable = true;
    inherit stateDir;
    workingDirectory = "${stateDir}/workspace";
    environmentFiles = [config.age.secrets.hermes_env.path];
    environment.HERMES_DOCKER_BINARY = "${pkgs.podman}/bin/podman";
    settings = {
      model = {
        provider = "custom";
        base_url = "http://127.0.0.1:20128/v1"; # 9router on loopback
        default = "ds/deepseek-v4.1-flash";
      };
      dashboard = {
        public_url = "https://hermes.gvarph.com";
        oauth = {
          provider = "self-hosted";
          self_hosted = {
            issuer = "https://id.gvarph.com";
            client_id = "eacb44bc-c76d-4fcb-a68d-fb2416ee68fb";
          };
        };
      };
      terminal = {
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
    # Browser dashboard on loopback; nginx fronts hermes.gvarph.com behind oauth2-proxy.
    # A public_url is required for that Host header and turns on Hermes's own
    # login gate: OIDC against Pocket ID with a public PKCE client.
    backend = {
      mode = "dashboard";
      host = "127.0.0.1";
      port = 9119;
    };
  };

  # Rootless podman for the sandbox: subordinate ids for the user namespace,
  # newuidmap from the setuid wrappers (hence NoNewPrivileges off for the
  # agent itself; the sandbox containers keep it on), and a runtime dir that
  # ProtectSystem=strict leaves writable.
  users.users.hermes.autoSubUidGidRange = true;
  systemd.services = lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
    after = ["zfs-mount.service"];
    unitConfig.ConditionPathIsMountPoint = stateDir;
    path = [pkgs.podman "/run/wrappers"];
    environment.XDG_RUNTIME_DIR = "/run/hermes";
    serviceConfig = {
      NoNewPrivileges = lib.mkForce false;
      RuntimeDirectory = "hermes";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = true;
    };
    # config.yaml/.env are (re)written at activation, not referenced by the
    # units, so changes would otherwise not restart the processes.
    restartTriggers = [
      config.age.secrets.hermes_env.file
      (builtins.toJSON config.services.hermes-agent.settings)
      (builtins.toJSON config.services.hermes-agent.environment)
      (builtins.toJSON config.services.hermes-agent.mcpServers)
    ];
  });
  systemd.tmpfiles.rules = ["d ${stateDir}/workspace 0750 hermes hermes -"];
}
