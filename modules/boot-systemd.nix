# Standard systemd-boot configuration with configurable kernel packages
{
  kernelPackages,
  ...
}: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    inherit kernelPackages;
  };
}
