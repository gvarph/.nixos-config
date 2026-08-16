# Keep sound on the motherboard's analog output (rear line-out, where the
# headphones are plugged in) by removing the GPU's HDMI audio entirely.
#
# The RX 9070 exposes a second PCI function, "Navi 48 HDMI/DP Audio Controller"
# (2b:00.1), which ALSA picks up as a full card whenever a display is awake.
# WirePlumber then hands it the default sink, which is how audio silently moved
# off the headphones. It also publishes a "Monitor of ..." loopback source, so
# the display shows up in microphone pickers despite having no mic.
#
# The display's speakers are not used, so drop the card at the WirePlumber
# level: its ALSA monitor checks device.disabled before creating the device
# (share/wireplumber/scripts/monitors/alsa.lua), so nothing is created — no
# sink, no monitor source, no default-sink competition. The kernel module and
# the motherboard's ALC1220 (2d:00.4) are untouched.
#
# Both matchers are ORed; device.product.name keeps the rule working if the GPU
# ever lands on a different PCI address. Undo by deleting this import and
# rebuilding — nothing here is destructive.
#
# PipeWire itself is enabled implicitly by programs.hyprland, via nixpkgs
# nixos/modules/services/misc/graphical-desktop.nix.
{
  services.pipewire.wireplumber.extraConfig."51-disable-gpu-hdmi-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {"device.name" = "alsa_card.pci-0000_2b_00.1";}
          {"device.product.name" = "Navi 48 HDMI/DP Audio Controller";}
        ];
        actions.update-props = {
          "device.disabled" = true;
        };
      }
    ];
  };
}
