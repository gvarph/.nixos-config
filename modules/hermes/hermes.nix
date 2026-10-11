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

  # DEEPSEEK_API_KEY: Hermes's own DeepSeek key (native provider, not 9router).
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
