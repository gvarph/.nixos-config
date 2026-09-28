{config, ...}: {
  age.secrets.crowdsec-web-ui_env.file = ../../secrets/crowdsec-web-ui_env.age;

  # CrowdSec dashboard (alerts, decisions, metrics). The LAPI and its
  # Prometheus endpoint only listen on loopback, so the container shares the
  # host network namespace; the firewall keeps :3005 off the LAN and nginx
  # fronts crowdsec.gvarph.com (native OIDC via Pocket ID).
  virtualisation.quadlet.containers.crowdsec-web-ui = {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service" "crowdsec-web-ui-machine.service"];
      Wants = ["crowdsec-web-ui-machine.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/crowdsec-web-ui";
    };
    containerConfig = {
      image = "ghcr.io/theduffman85/crowdsec-web-ui:2026.9.2";
      environmentFiles = [config.age.secrets.crowdsec-web-ui_env.path];
      environments = {
        CONFIG_SERVER_PORT = "3005"; # 3000 is grafana
        CONFIG_INSTANCE_NAME = "nas1";
        CONFIG_INSTANCE_LAPI_URL = "http://127.0.0.1:8082";
        CONFIG_INSTANCE_LAPI_AUTH_USERNAME = "crowdsec-web-ui";
        CONFIG_INSTANCE_METRICS_URL = "http://127.0.0.1:6060/metrics";
        # Pocket ID login; client id/secret come from the secret. Every
        # Pocket ID account is an admin here: the IdP has no groups for this app.
        CONFIG_AUTH_OIDC_ISSUER_URL = "https://id.gvarph.com";
        CONFIG_AUTH_OIDC_UNMATCHED_ROLE = "admin";
        CONFIG_UI_TIME_ZONE = "Europe/Prague";
        TZ = "Europe/Prague";
      };
      networks = ["host"];
      volumes = ["/flash/crowdsec-web-ui:/app/data:U"];
      userns = "auto";
      noNewPrivileges = true;
      healthCmd = "node -e \"fetch('http://127.0.0.1:3005/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))\"";
      healthInterval = "30s";
      healthTimeout = "5s";
      healthStartPeriod = "30s";
      healthRetries = 3;
      notify = "healthy";
    };
    serviceConfig.Restart = "on-failure";
  };

  # Register the UI as a LAPI watcher with the password from the secret.
  # --force makes it idempotent, so a secret rotation just re-runs it.
  systemd.services.crowdsec-web-ui-machine = {
    after = ["crowdsec.service"];
    requires = ["crowdsec.service"];
    path = [config.services.crowdsec.package];
    serviceConfig.Type = "oneshot";
    script = ''
      pw=$(sed -n 's/^CONFIG_INSTANCE_LAPI_AUTH_PASSWORD=//p' ${config.age.secrets.crowdsec-web-ui_env.path})
      cscli machines add crowdsec-web-ui --password "$pw" -f /dev/null --force
    '';
  };

  systemd.services.crowdsec-web-ui.restartTriggers = [config.age.secrets.crowdsec-web-ui_env.file];
}
