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
        -- Hyprland 0.56 clips custom hardware-cursor sprites (seen as a
        -- cut-off mouse cursor in Path of Exile / XWayland games); render
        -- the cursor in software instead. If the added latency ever
        -- bothers, try use_cpu_buffer = 1 with hardware cursors instead.
        no_hardware_cursors = 1,
    },
})
