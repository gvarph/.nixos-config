{...}: {
  # Hyprland config managed by home-manager. Hyprland 0.56 (git, 2026-07-24)
  # removed hyprlang support entirely — it only reads hyprland.lua — so the
  # config lives in the Lua files under ./lua, written to ~/.config/hypr and
  # require()d from the generated hyprland.lua.
  # Note: changes require a rebuild; the running session then auto-reloads.
  wayland.windowManager.hyprland = {
    enable = true;

    # Hyprland and its portal are installed by the NixOS module
    # (programs.hyprland in devices/desktop), pinned to the hyprland flake.
    package = null;
    portalPackage = null;

    configType = "lua";

    # The session (graphical-session.target, env import) is managed by UWSM
    # (programs.hyprland.withUWSM), so HM's own systemd integration would
    # fight it over the same targets.
    systemd.enable = false;

    extraLuaFiles = {
      autostart = ./lua/autostart.lua;
      input = ./lua/input.lua;
      keybinds = ./lua/keybinds.lua;
      monitors = ./lua/monitors.lua;
      theme = ./lua/theme.lua;
    };
  };

  # A running Hyprland generates a default hyprland.lua whenever its config
  # file goes missing (this is how the 0.56 upgrade left a stub behind),
  # which trips HM's clobber check during the switchover; overwrite it
  # instead of aborting activation.
  xdg.configFile."hypr/hyprland.lua".force = true;

  # Colors are set directly in lua/theme.lua. The catppuccin hyprland module
  # could now be enabled (it requires configType = "lua"), but that would
  # change border colors — revisit separately.
  catppuccin.hyprland.enable = false;
}
