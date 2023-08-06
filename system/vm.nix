{ config
, pkgs
, username
, gpuId #abcd:abcd
, soundId #abcd:abcd
, ...
}:

{

  # Optionally replace "master" with a particular revision to pin this dependency.
  # This repo also provides the module in a "Nix flake" under `nixosModules.nvidia-vgpu` output
  #imports = [
  #  (builtins.fetchTarball "https://github.com/danielfullmer/nixos-nvidia-vgpu/archive/master.tar.gz")
  #];

  #hardware.nvidia.vgpu.enable = true; # Enable NVIDIA KVM vGPU + GRID driver
  #hardware.nvidia.vgpu.unlock.enable = true; # Unlock vGPU functionality on consumer cards using DualCoder/vgpu_unlock project.

  boot.kernelParams = [
    "amd_iommu=on" #
    "iommu=pt"
    "pcie_acs_override=downstream,multifunction"
  ];


  ## Enable dconf (System Management Tool)
  programs.dconf.enable = true;

  ## Add user to libvirtd group
  users.users.${username}.extraGroups = [ "libvirtd" ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    gnome.adwaita-icon-theme
  ];

  #Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;



      qemu = {

        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  #services.spice-vdagentd.enable = true;


}
