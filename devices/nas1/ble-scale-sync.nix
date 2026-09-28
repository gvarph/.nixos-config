{config, ...}: {
  age.secrets.ble-scale-sync_env.file = ../../secrets/ble-scale-sync_env.age;

  # Xiaomi S400 scale -> JSONL/MQTT/Garmin via Home Assistant's Bluetooth
  # (ble.handler ha-bluetooth), so no radio or D-Bus access is needed here.
  # Upstream image since 1.27.0 carries the S400 and ha-bluetooth work.
  virtualisation.quadlet.containers.ble-scale-sync = {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/ble-scale-sync";
    };
    containerConfig = {
      image = "ghcr.io/kristianp26/ble-scale-sync:1.29.0";
      # Skip the entrypoint's Bluetooth adapter reset (moot on ha-bluetooth) and
      # point at the config dir: the app writes last_known_weight back into it.
      entrypoint = "tini";
      exec = "-- node dist/index.js --config /app/conf/config.yaml";
      user = "1000:100";
      environmentFiles = [config.age.secrets.ble-scale-sync_env.path];
      environments.CONTINUOUS_MODE = "true";
      volumes = [
        "/flash/ble-scale-sync:/app/conf"
        "/flash/ble-scale-sync/data:/app/data"
      ];
      noNewPrivileges = true;
    };
    serviceConfig.Restart = "on-failure";
  };

  systemd.services.ble-scale-sync.restartTriggers = [config.age.secrets.ble-scale-sync_env.file];
}
