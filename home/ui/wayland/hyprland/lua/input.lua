-- Input devices, layouts, environment variables

hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("NIXOS_OZONE_WL", "1")

hl.config({
	input = {
		kb_layout = "us",

		follow_mouse = 2,

		touchpad = {
			natural_scroll = false,
			disable_while_typing = true,
			tap_to_click = true,
		},

		sensitivity = 0, -- -1.0 to 1.0, 0 means no modification
		accel_profile = "flat",
	},

	dwindle = {
		preserve_split = true,
		smart_split = false,
		smart_resizing = true,
	},

	master = {
		new_status = "master",
		new_on_top = false,
	},

	cursor = {
		-- Hardware cursors keep the cursor out of screenshots: a software
		-- cursor (no_hardware_cursors = 1, and apparently use_cpu_buffer = 1
		-- too) is baked into every screencopy frame, grim/wayfreeze included.
		-- Hyprland 0.56 was clipping custom hardware-cursor sprites (a
		-- cut-off cursor in Path of Exile / XWayland games); if that
		-- returns, going back to 1 fixes it at the cost of cursors in
		-- screenshots.
		no_hardware_cursors = 0,
	},
})
