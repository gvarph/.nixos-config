-- Autostart processes

hl.on("hyprland.start", function()
	-- Hand the session env (WAYLAND_DISPLAY, HYPRLAND_INSTANCE_SIGNATURE, ...)
	-- to uwsm. Without it uwsm times out waiting and ends the session; since
	-- the 0.57 / systemd 262 / uwsm 0.27.2 update nothing else exports it.
	hl.exec_cmd("uwsm finalize")
	hl.exec_cmd("uwsm app -- waybar")
	-- Clipboard history daemon
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
