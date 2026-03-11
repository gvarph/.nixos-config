{
  config,
  pkgs,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../secrets/age.nix
    ../../modules/nix-maintenance.nix
    ../../modules/boot-systemd.nix
    #../../linux/features/kubernetes.nix
  ];

  networking.hostName = "nas1";
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
  ];

  boot.kernelModules = ["it87" "nct6775"]; # Common fan controller drivers

  boot.kernelParams = [
    # Enables PCIe power saving
    "pcie_aspm=force"
    # Helps some Ryzen chips reach deeper C-states
    "processor.max_cstate=5"
    # Required for some NVMe drives to sleep
    "nvme_core.default_ps_max_latency_us=0"
  ];

  powerManagement.cpuFreqGovernor = "powersave";
  powerManagement.powertop.enable = true;
}
