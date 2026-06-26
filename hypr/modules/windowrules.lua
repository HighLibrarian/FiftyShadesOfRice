--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Docs:
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/


-- =================================
-- =  MARK: GLOBAL WINDOW RULES    =
-- =================================

-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})


-- =================================
-- =  MARK: POPUP HELPER FUNCTION  =
-- =================================

-- Creates uniform dropdown popups for Waybar
local function BarDropDown(name, MatchProp, w, h, y)
    hl.window_rule({
        name = name,
        match = MatchProp,
        animation = "slide top",
        float = true,
        size = { w, h },
        move = {
            "(monitor_w - " .. w .. ") / 2",
            tostring(y or 50),
        },
        dim_around = true,
    })
end


-- =================================
-- =  MARK: WAYBAR POPUP WINDOWS   =
-- =================================

BarDropDown("bluetooth-manager", { class = "com.ezratweaver.AdwBluetooth" }, 500, 600, 40)
BarDropDown("emoji-picker",      { class = "dev.anishroy.omniglyph"       }, 500, 600, 0 )
BarDropDown("wallpaper-picker",  { class = "waypaper"                     }, 1300, 600, 40)


-- =================================
-- =  MARK: WORKSPACE MOVEMENT     =
-- =================================

-- Move all windows with tag "remote" to workspace 10
hl.window_rule({match = { tag = "remote" },workspace = 10})
hl.window_rule({match = { tag = "social" },workspace = "special:magic"})






-- =================================
-- =  MARK: LAYER RULES            =
-- =================================

hl.layer_rule({
    name = "notification-animations",
    match = { namespace = "swaync-control-center" },
    animation = "slide top"
})


-- =================================
-- =  MARK: SPECIAL WINDOW RULES   =
-- =================================

-- YouTube tabs: keep opacity unchanged
hl.window_rule({
    match = { title = ".*YouTube.*" },
    opacity = "1.0 override 1.0 override",
    no_dim = true,
})


-- =================================
-- =  MARK: TAGGING RULES          =
-- =================================

-- Protected windows
hl.window_rule({ match = { title = ".*FLX.*" }, tag = "protected" })
hl.window_rule({ match = { class = "discord" }, tag = "protected" })
hl.window_rule({ match = { class = "code"    }, tag = "protected" })


-- social windows
hl.window_rule({ match = { class = "discord" }, tag = "social" })

-- Auto‑move to remote workspace
hl.window_rule({ match = { class = "Horizon-client" }, tag = "remote" })
