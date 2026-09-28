{config, ...}: {
  age.secrets.paperless_env.file = ../../secrets/paperless_env.age;

  # Paperless-ngx with its own Postgres and Redis, plus paperless-gpt for LLM
  # OCR/tagging. nginx fronts paperless.gvarph.com (native OIDC to Pocket ID).
  # The compose stack's two metrics exporters were dropped with the metrics stack.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks;
    envFile = config.age.secrets.paperless_env.path;
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the datasets are missing.
      ConditionPathIsMountPoint = ["/flash/paperless" "/tank/paperless"];
    };
  in {
    # Fixed subnet so the gateway can be a trusted proxy (see immich.nix).
    networks.paperless.networkConfig = {
      subnets = ["10.90.2.0/24"];
      gateways = ["10.90.2.1"];
    };

    containers.paperless-broker = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/library/redis:8.10.2";
        networks = [networks.paperless.ref];
        volumes = ["/flash/paperless/redis:/data:U"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.paperless-db = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/library/postgres:18.6";
        # Only reachable on the private network; same value the compose stack used.
        environments = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = "paperless";
          POSTGRES_PASSWORD = "paperless";
        };
        networks = [networks.paperless.ref];
        volumes = ["/flash/paperless/pg:/var/lib/postgresql:U"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.paperless = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["paperless-db.service" "paperless-broker.service"];
          Requires = ["paperless-db.service" "paperless-broker.service"];
        };
      containerConfig = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:3.2.1";
        # USERMAP_UID/GID=1000:100 in the env file: the image starts as root
        # and drops to that uid, which owns data/, consume/ and the media tree.
        environmentFiles = [envFile];
        environments = {
          PAPERLESS_REDIS = "redis://paperless-broker:6379";
          PAPERLESS_DBHOST = "paperless-db";
          # Real client IPs in "Login failed" lines (crowdsec reads them).
          PAPERLESS_TRUSTED_PROXIES = "10.90.2.1";
        };
        networks = [networks.paperless.ref];
        publishPorts = ["127.0.0.1:13388:8000"];
        volumes = [
          "/flash/paperless/data:/usr/src/paperless/data"
          "/tank/paperless/media:/usr/src/paperless/media"
          "/tank/paperless/export:/usr/src/paperless/export"
          "/flash/paperless/consume:/usr/src/paperless/consume"
        ];
        noNewPrivileges = true;
        healthCmd = "curl -fs -S --max-time 2 http://localhost:8000";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "60s";
        healthRetries = 5;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.paperless-gpt = {
      autoStart = true;
      unitConfig = {
        After = ["paperless.service" "9router.service"];
        Requires = ["paperless.service"];
      };
      containerConfig = {
        image = "docker.io/icereed/paperless-gpt:v0.28.0";
        # Shares the env file for PAPERLESS_API_TOKEN and OPENAI_API_KEY (a 9router key).
        environmentFiles = [envFile];
        # LLM traffic goes to 9router on its own network, not to DeepSeek directly.
        environments = {
          PAPERLESS_BASE_URL = "http://paperless:8000";
          LLM_PROVIDER = "openai";
          # V4.1 Flash is natively multimodal; the separate vision-exp model was retired 2026-09-10.
          LLM_MODEL = "ds/deepseek-v4.1-flash";
          VISION_LLM_PROVIDER = "openai";
          VISION_LLM_MODEL = "ds/deepseek-v4.1-flash";
          OPENAI_BASE_URL = "http://9router:20128/v1";
          OCR_PROVIDER = "llm";
          OCR_LIMIT_PAGES = "5";
          CREATE_LOCAL_HOCR = "false";
          LOCAL_HOCR_PATH = "/app/hocr";
          PDF_COPY_METADATA = "true";
          PDF_OCR_TAGGING = "true";
          PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete";
        };
        networks = [networks.paperless.ref networks."9router".ref];
        # Loopback only; its review UI has no vhost yet.
        publishPorts = ["127.0.0.1:23489:8080"];
        volumes = ["/tank/paperless/hocr:/app/hocr:U"];
        # Its entrypoint creates a user at uid 10001; auto's default 1024-id map is too small.
        userns = "auto:size=65536";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services = {
    paperless.restartTriggers = [config.age.secrets.paperless_env.file];
    paperless-gpt.restartTriggers = [config.age.secrets.paperless_env.file];
  };
}
