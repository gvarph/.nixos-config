{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  stateDir = "/var/lib/hermes";
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
    (asHermes "hermes" (lib.getExe' cfg.package "hermes"))
    (asHermes "hermes-shell" "bash")
  ];

  # DEEPSEEK_API_KEY (primary), DEEPINFRA_API_KEY (fallback), AGENTMAIL_API_KEY, Discord.
  age.secrets.hermes_env = {
    file = ../../secrets/hermes_env.age;
    owner = "hermes";
  };

  # The agent runs natively as the unprivileged `hermes` user; its shell /
  # Python commands run in the podman sandbox (sandbox.nix).
  services.hermes-agent = {
    enable = true;
    inherit stateDir;
    workingDirectory = "${stateDir}/workspace";
    environmentFiles = [config.age.secrets.hermes_env.path];
    settings = {
      # DeepSeek V4.1 Flash on DeepSeek's own API. Native providers handle V4's
      # thinking toggle. Explicit base_url, so no leftover value in the
      # deep-merged config.yaml applies.
      model = {
        provider = "deepseek";
        default = "deepseek-flash"; # = DeepSeek-V4.1-Flash
        base_url = "https://api.deepseek.com/v1";
      };
      # Same model on DeepInfra when DeepSeek fails or hits its limits.
      fallback_providers = [
        {
          provider = "deepinfra";
          model = "deepseek-ai/DeepSeek-V4.1-Flash";
          base_url = "https://api.deepinfra.com/v1/openai";
        }
      ];
      # Photos go to the model natively (V4.1 Flash reads images; tested on all
      # endpoints). Vision is pinned to DeepSeek, falling back along the chain above.
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

  systemd.services = lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
    after = ["zfs-mount.service"];
    unitConfig.ConditionPathIsMountPoint = stateDir;
    # config.yaml/.env are (re)written at activation, not referenced by the
    # units, so changes would otherwise not restart the processes.
    restartTriggers = [
      config.age.secrets.hermes_env.file
      (builtins.toJSON cfg.settings)
      (builtins.toJSON cfg.environment)
      (builtins.toJSON cfg.mcpServers)
    ];
  });
  systemd.tmpfiles.rules = ["d ${stateDir}/workspace 0750 hermes hermes -"];
}
