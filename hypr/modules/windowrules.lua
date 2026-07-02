--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Docs:
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/


-- =================================
-- =  MARK: GLOBAL WINDOW RULES    =
-- =================================
-- get our hostname in case we want host specific window rules
local hostname = io.popen("hostname"):read("*l")

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
local function BarDropDown(name, MatchProp, w, h, y,o)
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
        opacity = o
    })
end


-- =================================
-- =  MARK: WAYBAR POPUP WINDOWS   =
-- =================================

BarDropDown("bluetooth-manager", { class = "com.ezratweaver.AdwBluetooth" }, 500, 600, 40,0.85)
BarDropDown("emoji-picker",      { class = "dev.anishroy.omniglyph"       }, 500, 600, 0,1 )
BarDropDown("wallpaper-picker",  { class = "waypaper"                     }, 1300, 600, 40, 0.85)
BarDropDown("localsend",         { class = "localsend"                    }, 500, 600, 40, 0.7)
BarDropDown("home-assistant",    { initial_title = "Home Assistant"       }, 900, 1000, 40, 0.7)





-- =================================
-- =  MARK: WORKSPACE MOVEMENT     =
-- =================================

-- Move all windows with tag "remote" to workspace 10
hl.window_rule({match = { tag = "remote" },workspace = 10})

-- Move all windows with tag "remote" to workspace magic
hl.window_rule({match = { tag = "social" },workspace = "special:magic"})

-- Mova all games to workspace 9 and make them fullscreen
hl.window_rule({name = "fullscreen-steam-games",match = { class = "^steam_app_.*" },workspace = 9,fullscreen = true,})
hl.window_rule({name = "steam",match = { class = "steam" },workspace = 1})





-- =================================
-- =  MARK: LAYER RULES            =
-- =================================

hl.layer_rule({
    name = "notification-animations",
    match = { namespace = "swaync-control-center" },
    animation = "slide top",
    ignore_alpha = 0.5
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
hl.window_rule({ match = { title = ".*FLX.*"          }, tag = "protected" })
hl.window_rule({ match = { title = ".*DCK.*"          }, tag = "protected" })
hl.window_rule({ match = { class = "discord"          }, tag = "protected" })
hl.window_rule({ match = { class = "code"             }, tag = "protected" })
hl.window_rule({ match = { class = "^steam_app_.*"    }, tag = "protected" })


-- social windows
hl.window_rule({ match = { class = "discord" }, tag = "social" })
hl.window_rule({ match = { class = "signal"  }, tag = "social" })

-- Auto‑move to remote workspace
hl.window_rule({ match = { class = "Horizon-client" }, tag = "remote" })
hl.window_rule({ match = { class = "Wfica"          }, tag = "remote" })
hl.window_rule({ match = { initial_class = "Vmware" }, tag = "remote" })


-- =================================
-- =  MARK: System specifc         =
-- =================================

if hostname == "HyprStation-01" then
    hl.window_rule({name = "flameshot-home",match = { class = "flameshot" },
        float = true,
        pin = true,
        move = {0, -190},
        size = {4520, 1920},
    })
end


