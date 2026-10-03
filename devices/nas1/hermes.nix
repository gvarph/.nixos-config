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

  # `hermes …` and `hermes-shell` run the CLI / a shell as the hermes user with
  # the gateway unit's exact environment (paths, sandbox runtime dir).
  environment.systemPackages = let
    asHermes = name: cmd:
      pkgs.writeShellScriptBin name ''
        env_args=$(systemctl show hermes-agent -p Environment --value)
        exec sudo -u hermes env -i $env_args TERM="''${TERM:-xterm}" \
          sh -c 'cd ${stateDir}/workspace && exec ${cmd} "$@"' ${name} "$@"
      '';
  in [
    (asHermes "hermes" (lib.getExe' config.services.hermes-agent.package "hermes"))
    (asHermes "hermes-shell" "bash")
  ];

  # DEEPSEEK_API_KEY: Hermes's own DeepSeek key (native provider, not 9router).
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
    environment = {
      HERMES_DOCKER_BINARY = "${pkgs.podman}/bin/podman";
      SEARXNG_URL = "http://127.0.0.1:8888";
    };
    settings = {
      # Native DeepSeek provider: it handles V4's thinking toggle / reasoning echo,
      # which an anonymous OpenAI-compatible hop (9router) does not.
      # config.yaml is deep-merged, so the old 9router keys are blanked explicitly.
      model = {
        provider = "deepseek";
        default = "deepseek-flash"; # = DeepSeek-V4.1-Flash (vision, tools)
        # Explicit, so no leftover top-level base_url can fill a blank.
        base_url = "https://api.deepseek.com/v1";
      };
      # Photos go to the model natively (deepseek-flash reads images, also inside
      # tool results; tested). The vision fallback route is pinned to DeepSeek so
      # other keys in the env (e.g. DeepInfra) never become a photo destination.
      # Side tasks follow the provider's default aux model (deepseek-flash).
      agent.image_input_mode = "native";
      auxiliary = let
        followMain = extra:
          {
            provider = "auto";
            model = "";
            base_url = "";
            key_env = "";
          }
          // extra;
      in {
        vision = followMain {
          provider = "deepseek";
          model = "deepseek-flash";
          base_url = "https://api.deepseek.com/v1";
        };
        compression = followMain {max_concurrency = 2;};
        title_generation = followMain {};
      };
      # Voice notes transcribed on nas1 (faster-whisper); nothing leaves the box.
      stt = {
        enabled = true;
        provider = "local";
        language = ""; # auto-detect (default would force English)
        echo_transcripts = false; # don't post transcripts back into chats
        local = {
          model = "large-v3-turbo";
          device = "cpu";
          compute_type = "int8";
        };
      };
      # Search via local SearXNG only; never fall back to public keyless APIs.
      web = {
        search_backend = "searxng";
        keyless_fallback = false;
        keyless_rescue = false;
      };
      # The browser tool would run on the host, outside the sandbox: keep it off.
      browser = {
        backend = "off";
        allow_private_urls = false;
      };
      # Trek: plain OAuth (dynamic client registration), all tools; the scopes
      # approved on Trek's consent page decide what it may do. One-time login
      # as hermes: `hermes mcp login trek`. Typed mcpServers has no oauth block.
      mcp_servers.trek = {
        url = "https://trek.gvarph.com/mcp";
        auth = "oauth";
        # Fixed loopback callback, so the login also works through an SSH tunnel.
        oauth = {
          redirect_host = "127.0.0.1";
          redirect_port = 27899;
        };
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
    # MCP servers: read tools only, each by explicit allowlist (write tools are
    # added only on request). Stdio servers run on the host as hermes.
    mcpServers = {
      victoriametrics = {
        command = lib.getExe pkgs.mcp-victoriametrics;
        env = {
          VM_INSTANCE_ENTRYPOINT = "http://127.0.0.1:8428";
          VM_INSTANCE_TYPE = "single";
        };
        # No alerts/rules: without vmalert they are always empty ("nothing firing").
        tools.include = [
          "query"
          "query_range"
          "metrics"
          "metrics_metadata"
          "labels"
          "label_values"
          "series"
          "metric_statistics"
          "tsdb_status"
          "documentation"
          "prettify_query"
          "explain_query"
        ];
      };
      victorialogs = {
        command = lib.getExe pkgs.mcp-victorialogs;
        env.VL_INSTANCE_ENTRYPOINT = "http://127.0.0.1:9428";
        tools.include = [
          "query"
          "hits"
          "facets"
          "field_names"
          "field_values"
          "stats_query"
          "stats_query_range"
          "streams"
          "stream_ids"
          "stream_field_names"
          "stream_field_values"
          "documentation"
        ];
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
  # Rootless podman joins the mount namespace of its long-lived "pause" process.
  # Created from inside a hardened unit (PrivateTmp etc.) that namespace goes
  # stale on restart (no /tmp, /var/tmp -> exit 127). This unprivileged unit
  # without private mounts creates it first, replacing any stale one.
  systemd.services = lib.mkMerge [
    {
      hermes-podman-pause = {
        description = "Rootless podman pause process for the Hermes sandbox";
        after = ["zfs-mount.service"];
        unitConfig.ConditionPathIsMountPoint = stateDir;
        path = [pkgs.podman "/run/wrappers" pkgs.coreutils];
        environment = {
          HOME = stateDir;
          XDG_RUNTIME_DIR = "/run/hermes";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "hermes";
          Group = "hermes";
          RuntimeDirectory = "hermes";
          RuntimeDirectoryMode = "0700";
          RuntimeDirectoryPreserve = true;
          ExecStartPre = "-${pkgs.bash}/bin/sh -c 'kill $(cat /run/hermes/libpod/tmp/pause.pid) 2>/dev/null; true'";
          ExecStart = "${pkgs.podman}/bin/podman unshare true";
        };
      };
    }
    (lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
      after = ["zfs-mount.service" "hermes-podman-pause.service"];
      requires = ["hermes-podman-pause.service"];
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
    }))
  ];
  systemd.tmpfiles.rules = ["d ${stateDir}/workspace 0750 hermes hermes -"];
}
