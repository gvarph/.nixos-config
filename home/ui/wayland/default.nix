{pkgs, ...}: {
  home.packages = with pkgs; [
    chromium
    (pkgs.symlinkJoin {
      name = "mongodb-compass";
      paths = [pkgs.mongodb-compass];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/mongodb-compass \
          --add-flags "--password-store=gnome-libsecret --ignore-additional-command-line-flags"
      '';
    })
    hyprcursor
  ];

  imports = [
    ./hyprland
    ./waybar
    ./rofi.nix
    ./hypridle
    ./hyprlock
    ./polkit
    ./mako
    ./udiskie
  ];

  home.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    ELECTRON_ENABLE_WAYLAND = "1";
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
