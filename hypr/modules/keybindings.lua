
----------------------------------
-- MARK: App and key definition --
----------------------------------
local terminal      = "kitty"
local fileManager   = "nautilus --new-window"
local screenshot    = "hyprshot -m region"
local menu          = "~/.config/rofi/launcher/app-launcher.sh"
local browser       = "~/.config/hypr/scripts/start-edge.sh"
local statusbar     = "~/.config/waybar/scripts/launch.sh"
local notifications = "swaync-client -t -sw"
local missioncenter = "flatpak run io.missioncenter.MissionCenter"

-- keys and buttons
local mainMod       = "SUPER"
local lmb           = "mouse:272"
local rmb           = "mouse:273"


--------------------------
-- MARK: window control --
--------------------------

-- kill hyprland and return to login screen
hl.bind("CTRL + ALT + DELETE",hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- close window
hl.bind(mainMod .. " + Q",    hl.dsp.window.close())

-- toggle tiling mode for active window
hl.bind(mainMod .. " + T",    hl.dsp.window.float({ action = "toggle" }))

-- toggle fullscreen mode for active window
hl.bind(mainMod .. " + F",    hl.dsp.window.fullscreen({ action = "toggle" }))


-----------------------------
-- MARK: Apps and Launcher --
-----------------------------

-- open terminal (definition)
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))

-- activate lockscreen (definition)
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))

-- open notifications (definition)
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd(notifications))

-- open menu (definition)
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))

-- open or restart statusbar (definition)
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd(statusbar))

-- open obsidian
hl.bind(mainMod .. " + O",      hl.dsp.exec_cmd("flatpak run md.obsidian.Obsidian"))

-- open browser (definition)
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))

-- take screenshot (definition)
hl.bind("Print",                hl.dsp.exec_cmd(screenshot))

-- open the file manager
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))

-- open missioncenter
hl.bind("CTRL+SHIFT+ESCAPE",    hl.dsp.exec_cmd(missioncenter))

--------------------------------
-- MARK: Workspace management --
--------------------------------

-- Move focus with mainMod + vim keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
-- Use physical keycodes so top-row workspace binds work across keyboard layouts.
local ws_keys = {
    [1]  = "code:10",
    [2]  = "code:11",
    [3]  = "code:12",
    [4]  = "code:13",
    [5]  = "code:14",
    [6]  = "code:15",
    [7]  = "code:16",
    [8]  = "code:17",
    [9]  = "code:18",
    [10] = "code:19", -- physical 0 key
}

-- for workspace 1 to 10, get the matching ws_key and assign it to a workspace_id
for workspaceid = 1, 10 do
    local key = ws_keys[workspaceid]
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = workspaceid }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspaceid }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",                  hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",          hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",           hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272",          hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",          hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. "+ ALT_L",               hl.dsp.window.resize(), { mouse = true })







---------------------------
-- MARK: Multimedia keys --
---------------------------

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Play, pause, etc ... (Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })



--------------------------
-- MARK: disabled stuff --
--------------------------
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
