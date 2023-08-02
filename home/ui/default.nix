{ pkgs, config, username, ... }:
let
  # Variables to share accross configs
  custom = {
    font = "FiraCode Nerd Font";
    fontsize = "12";
    primary_accent = "cba6f7";
    secondary_accent = "89b4fa";
    tertiary_accent = "f5f5f5";
    background = "11111B";
    opacity = ".85";
    cursor = "Numix-Cursor";
  };
in
{
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
  environment.sessionVariables =
    {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

  home-manager.users.${username} = {

    imports =
      [
        #./packages.nix
        #(import ./general { inherit (inputs) self; })
        (import ./themes {
          inherit pkgs custom;
        })
        (import ./wayland { inherit pkgs custom; })
      ];

    home.packages = with pkgs; [
      vscode
      discord
      betterdiscordctl
      libnotify
      firefox

      steam
      lutris
      prismlauncher

      pulseaudio

    ];

  };
}
