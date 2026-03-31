{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U7NJ0XC36632A";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
      };
      options = {
        ashift = "12";
      };

      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
        };

        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };

        home = {
          type = "zfs_fs";
          mountpoint = "/home";
        };
      };
    };
  };
}
