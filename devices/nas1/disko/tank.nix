{
  disko.devices = {
    disk = {
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD40EFZZ-68CPAN0_WD-WX22DC50PLHY";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD40EFZZ-68CPAN0_WD-WX22DC50P3T3";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD40EFZZ-68CPAN0_WD-WX22DC50PKXN";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD40EFZZ-68CPAN0_WD-WX22DC50PK6H";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };

    zpool.tank = {
      type = "zpool";
      mode = "raidz1";
      options = {
        ashift = "12";
        autotrim = "on"; # Good practice even for HDDs if they support it
      };
      rootFsOptions = {
        compression = "lz4"; # Faster than zstd for general storage
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        "com.sun:auto-snapshot" = "true"; # Useful if you use a tool like zrepl or sanoid
      };

      datasets = {
        # General purpose network share
        storage = {
          type = "zfs_fs";
          mountpoint = "/tank/storage";
          options = {
            mountpoint = "legacy"; # Add this!
            compression = "zstd";
            recordsize = "128k";
          };
        };

        # Immich: Optimized for thousands of small files/photos
        immich = {
          type = "zfs_fs";
          mountpoint = "/tank/immich";
          options = {
            mountpoint = "legacy"; # Add this!
            recordsize = "128k";
          };
        };

        paperless = {
          type = "zfs_fs";
          mountpoint = "/tank/paperless";
          options = {
            mountpoint = "legacy"; # Add this!
            compression = "zstd";
            recordsize = "32k";
          };
        };

        # Media: Optimized for large sequential video files
        media = {
          type = "zfs_fs";
          mountpoint = "/tank/media";
          options = {
            mountpoint = "legacy"; # Add this!
            compression = "zstd";
            recordsize = "1M";
          };
        };
      };
    };
  };
}
