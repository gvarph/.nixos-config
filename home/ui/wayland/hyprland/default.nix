{...}: {
  # Hyprland config managed by home-manager (ported from the old
  # out-of-store-symlinked hyprland/config/*.conf files).
  # Note: changes now require a rebuild; `hyprctl reload` alone is not enough.
  imports = [
    ./theme.nix
    ./keybinds.nix
    ./monitors.nix
    ./input.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    # Hyprland and its portal are installed by the NixOS module
    # (programs.hyprland in devices/desktop), pinned to the hyprland flake.
    package = null;
    portalPackage = null;

    # Keep the classic hyprland.conf. Hyprland 0.55 deprecates hyprlang in
    # favour of Lua; the HM default flips to "lua" at stateVersion 26.05,
    # so pin hyprlang explicitly until this config is ported to Lua.
    configType = "hyprlang";

    # The session (graphical-session.target, env import) is managed by UWSM
    # (programs.hyprland.withUWSM), so HM's own systemd integration would
    # fight it over the same targets.
    systemd.enable = false;

    settings = {
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "uwsm app -- waybar"
        # Clipboard history daemon
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];
    };
  };

  # The still-running session regenerates a stub hyprland.conf (through the
  # previous generation's out-of-store symlink) whenever the file goes
  # missing, which trips HM's clobber check during the switchover; overwrite
  # it instead of aborting activation.
  xdg.configFile."hypr/hyprland.conf".force = true;

  # The catppuccin hyprland module only supports configType = "lua" (it
  # injects a mkLuaInline theme import, which would corrupt a hyprlang
  # config). Colors in theme.nix are set directly anyway.
  catppuccin.hyprland.enable = false;
}
