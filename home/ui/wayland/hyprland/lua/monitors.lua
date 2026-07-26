-- Monitor configuration
-- Use 'hyprctl monitors' to see available monitors

-- ASUS PG32UCDP 4K (main display at 240Hz with 1.5x scaling)
hl.monitor({
	output = "DP-2",
	mode = "3840x2160@240",
	position = "1920x0",
	scale = "1.5",
	supports_hdr = 0,
	vrr = 2,
})

-- Samsung 1920x1080 (left monitor) - positioned down to align bottoms
hl.monitor({
	output = "DP-1",
	mode = "1920x1080@60",
	position = "0x350",
	scale = "1",
})

-- ASUS MB16AC 15.6" portable monitor (centered under DP-1)
-- Higher PPI than 24" 1080p, so scaled to 1.25 for similar physical UI size
hl.monitor({
	output = "DVI-I-1",
	mode = "1920x1080@60",
	position = "350x1430",
	scale = "1.25",
})

-- AOC 24" HDMI monitor (right of main, rotated 90° counterclockwise for vertical orientation)
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "4480x-250",
	scale = "1",
	transform = 3,
})

-- Fallback for any other monitors
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

-- Pin workspaces to monitors: left column (1,4,7), main (2,5,8),
-- vertical (3,6,9). Each monitor starts on its `default = true` one.
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "7", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-2" })
hl.workspace_rule({ workspace = "8", monitor = "DP-2" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-1" })

hl.config({
	xwayland = {
		force_zero_scaling = true,
		use_nearest_neighbor = true,
	},
})
