---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "be",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            scroll_factor = 0.25
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


-- media and volume control with 4-finger vertical swipes and taps
hl.gesture({ 
    fingers = 4,
    direction = "up",
    action = function() hl.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") end
})

hl.gesture({ 
    fingers = 4,
    direction = "down",
    action = function() hl.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-") end
})




-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})



