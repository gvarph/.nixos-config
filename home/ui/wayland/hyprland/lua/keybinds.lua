-- Keybindings: basic binds for common actions

local mod         = "SUPER"
local terminal    = "ghostty"
local fileManager = "ghostty -e yazi"
local menu        = "rofi -show drun"

-- Application shortcuts
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("uwsm app -- " .. terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("uwsm app -- " .. fileManager))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("uwsm app -- " .. menu))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("uwsm app -- " .. menu))
-- cliphist history with image thumbnails
hl.bind(mod .. " + V", hl.dsp.exec_cmd("clipboard-picker"))

-- Window management
hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())            -- dwindle
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))      -- dwindle
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("hyprlock"))  -- Lock screen

-- Move focus with arrow keys
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move focus with vim keys
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move windows with SHIFT + arrow keys
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Workspaces: switch (mod), move window (mod+SHIFT),
-- move window silently (mod+CTRL+SHIFT). Key 0 maps to workspace 10.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,                      hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,              hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + CTRL + SHIFT + " .. key,       hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Scroll through workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Screenshot (requires grim and slurp)
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("Print",               hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd('mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'))

-- Media keys
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Repeating binds (held keys keep firing)

-- Resize windows with CTRL + arrow keys
hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })

-- Brightness control
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- Move/resize windows with mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
