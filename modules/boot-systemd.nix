# Standard systemd-boot configuration with stable LTS kernel
{pkgs, ...}: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Using 6.12 LTS for better hardware compatibility (especially DisplayLink)
    kernelPackages = pkgs.linuxPackages_6_12;
  };
}
