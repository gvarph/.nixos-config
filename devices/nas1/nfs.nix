{
  # NFSv4 exports. /export is the pseudo-root (fsid=0); each shared dataset is
  # bind-mounted under it and exported with its own fsid. Clients mount paths
  # relative to the root, e.g. 10.0.1.185:/ha-backups
  #
  # To add a share: add a bind mount + an export line with the next free fsid.
  #
  # ZFS has no UUID/device number, so every export needs an explicit fsid.
  services.nfs.server = {
    enable = true;
    exports = ''
      /export            10.0.30.117(ro,fsid=0,no_subtree_check,crossmnt)
      /export/ha-backups 10.0.30.117(rw,sync,no_subtree_check,no_root_squash,fsid=1)
    '';
  };

  systemd.tmpfiles.rules = ["d /export 0755 root root -"];

  fileSystems."/export/ha-backups" = {
    device = "/tank/ha-backups";
    fsType = "none";
    options = ["bind"];
  };

  # v4 only: one data port, no mountd/statd port pinning.
  services.nfs.settings.nfsd = {
    vers3 = false;
    vers4 = true;
    "vers4.0" = true;
    "vers4.1" = true;
    "vers4.2" = true;
  };

  # 111 is required: HA mounts without `vers=`, so mount.nfs negotiates via rpcbind.
  networking.firewall.allowedTCPPorts = [2049 111 20048];
  networking.firewall.allowedUDPPorts = [111 20048];
}
