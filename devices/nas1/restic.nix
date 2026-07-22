{
  config,
  lib,
  ...
}: let
  # Hetzner Storage Box BX11 (FSN1). SSH on port 23, key-only auth.
  # The box must have the "restic-nas1" public key added in the Hetzner
  # console (comment: restic-nas1).
  storageBoxUser = "u636961";
  storageBoxHost = "u636961.your-storagebox.de";

  # Datasets that hold irreplaceable data. tank/media is deliberately
  # excluded (refetchable), as are rpool/{root,nix} (rebuilt from this
  # repo) and tank/snapshots (already a backup).
  datasets = [
    "rpool/flash" # children hold app state; the parent itself is legacy-mounted and skipped
    "rpool/home"
    "tank/immich"
    "tank/storage"
    "tank/paperless"
  ];
  datasetArgs = builtins.concatStringsSep " " datasets;

  # Systemd units run with a minimal PATH that lacks zfs
  zfs = "${config.boot.zfs.package}/bin/zfs";

  # One command per dataset: `zfs snapshot` with several args only works
  # within a single pool, and `zfs destroy` takes a single argument.
  # rpool/flash gets -r so its per-app children are covered.
  destroySnapshots = lib.concatMapStringsSep "\n" (d: "${zfs} destroy ${lib.optionalString (d == "rpool/flash") "-r "}${d}@restic 2>/dev/null || true") datasets;
  createSnapshots = lib.concatMapStringsSep "\n" (d: "${zfs} snapshot ${lib.optionalString (d == "rpool/flash") "-r "}${d}@restic") datasets;
in {
  age.secrets.hetzner_storagebox_ssh_key.file = ../../secrets/hetzner_storagebox_ssh_key.age;
  age.secrets.restic_hetzner_password.file = ../../secrets/restic_hetzner_password.age;

  # Hetzner does not publish Storage Box host keys; this was pinned via
  # ssh-keyscan on 2026-07-22.
  programs.ssh.knownHosts."storagebox" = {
    hostNames = ["[${storageBoxHost}]:23"];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };

  services.restic.backups.hetzner-storagebox = {
    initialize = true;
    repository = "sftp:${storageBoxUser}@${storageBoxHost}:restic-nas1";
    passwordFile = config.age.secrets.restic_hetzner_password.path;

    # Cap upload at 4 MiB/s (~32 Mbit): ~2/3 of the 50 Mbit uplink, so
    # backups (especially the initial seed) don't starve everything else
    extraBackupArgs = ["--limit-upload=4096"];
    extraOptions = [
      "sftp.command='ssh -p 23 -i ${config.age.secrets.hetzner_storagebox_ssh_key.path} ${storageBoxUser}@${storageBoxHost} -s sftp'"
    ];

    # Back up from a fixed-name ZFS snapshot instead of the live
    # filesystems, so databases (immich postgres etc.) are captured at a
    # single instant. Stable .zfs/snapshot/restic paths keep restic's
    # parent-snapshot detection and dedup working across runs.
    backupPrepareCommand = ''
      ${destroySnapshots}
      ${createSnapshots}
    '';
    backupCleanupCommand = ''
      ${destroySnapshots}
    '';

    # Emit the snapshot dir of every mounted dataset; unmounted/legacy
    # datasets (the bare rpool/flash parent) are skipped.
    dynamicFilesFrom = ''
      ${zfs} list -H -o mountpoint -r ${datasetArgs} \
        | grep -v '^\(legacy\|none\|-\)$' \
        | sed 's|$|/.zfs/snapshot/restic|'
    '';

    timerConfig = {
      OnCalendar = "03:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
}
