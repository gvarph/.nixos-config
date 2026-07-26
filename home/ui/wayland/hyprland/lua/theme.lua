-- Visual settings: borders, gaps, colors, animations, window/layer rules

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,

		col = {
			-- Gradient border colors (blue to teal)
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		layout = "dwindle",
		allow_tearing = false,
	},

	decoration = {
		rounding = 10,

		blur = {
			enabled = true,
			size = 8,
			passes = 2,
			new_optimizations = true,
			-- Blur layer-shell popups (menus, tooltips) too
			popups = true,
		},
	},

	animations = {
		enabled = true,
	},
})

-- No gaps when there's only one window in a workspace
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

-- Borderless + square when a workspace has a single tiled window…
hl.window_rule({
	name = "seamless-single-window",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
-- …or a fullscreen one
hl.window_rule({
	name = "seamless-fullscreen",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

-- Float pavucontrol as a centered popup
hl.window_rule({
	name = "pavucontrol-popup",
	match = { class = "org.pulseaudio.pavucontrol" },
	float = true,
	size = "800 600",
	center = true,
})

-- Awakened PoE Trade: floating overlay with no chrome or effects.
-- Two effects here are load-bearing:
-- - no_focus: the overlay is an invisible window covering the whole
--   game monitor, and without it Hyprland gives it focus on click
--   (clicks pass through to the game, so playing feels normal) — then
--   APT's synthetic Ctrl+C lands on itself instead of the game and
--   price checking silently fails.
-- - pin: fullscreen windows get exclusive rendering on their
--   workspace, so the overlay is invisible over the fullscreen game
--   unless pinned (pinned floats render above fullscreen).
hl.window_rule({
	name = "apt-rule",
	match = { class = "^(awakened-poe-trade|Awakened-poe-trade)$" },
	float = true,
	pin = true,
	border_size = 0,
	no_blur = true,
	no_shadow = true,
	no_anim = true,
	no_focus = true,
	-- might be unnecessary
	no_follow_mouse = true,
})

-- Blur the rofi launcher so it matches the window blur; no animation, so
-- the launcher snaps instead of animating its resize as you type
hl.layer_rule({
	name = "rofi",
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.5,
	no_anim = true,
})

-- Waybar: its bar background is already translucent (rgba .3), so blur
-- what's behind it; low ignore_alpha so the faint bar bg still blurs
hl.layer_rule({
	name = "waybar",
	match = { namespace = "waybar" },
	blur = true,
	ignore_alpha = 0.2,
})

-- Mako notifications (translucency set in mako's own config)
hl.layer_rule({
	name = "notifications",
	match = { namespace = "notifications" },
	blur = true,
	ignore_alpha = 0.5,
})

-- Custom bezier curves
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "smoothIn" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 7, bezier = "smoothIn" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
