---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:



hl.on("hyprland.start", function () 

-- =================================
-- =  MARK: General                =
-- =================================
  
  -- get our hostname in case we want host specific startup apps
  local hostname = io.popen("hostname"):read("*l")


  -- Chain D-Bus update, systemd import, and keyring replacement sequentially
  hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd --all && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && gnome-keyring-daemon --replace --start --components=secrets,pkcs11,ssh'")

  -- Wallpaper services
  hl.exec_cmd("awww-daemon") 
  hl.exec_cmd("waypaper --restore") 
  
  -- Desktop environment components
  hl.exec_cmd("waybar") -- our top bar
  hl.exec_cmd("hyprsunset") -- nightlight 
  hl.exec_cmd("swaync") -- notifications
  hl.exec_cmd("/usr/libexec/hyprpolkitagent")
  
  -- applications

  hl.exec_cmd("flatpak run com.discordapp.Discord")

  hl.exec_cmd("~/AppImages/obsidian.appimage")
  -- start onedrive
  hl.exec_cmd("onedrive --sync")

-- =================================
-- =  MARK: System specifc         =
-- =================================

  if hostname == "HyprStation-01" then
    hl.exec_cmd("notify-send 'Loaded config for ' '" .. hostname .. "'")

    -- load audio switcher
    hl.exec_cmd("~/.local/bin/las daemon")
    
    -- load rbg profile
    hl.exec_cmd("openrgb --profile ~/.config/OpenRGB/HyprStation-01.orp")

    -- load you hypridle desktop profile 
    hl.exec_cmd("hypridle -c ~/.config/hypridle/hypridle-desktop.conf")

    -- load our secrets. note you might need to enter your password
    hl.exec_cmd("~./config/hypr/scripts/get-secrets.sh")

    -- load lnxlink
    hl.exec_cmd ("~/.local/bin/lnxlink -c ~/.config/LNXlink/config.yaml")

    -- restore balanced powerplan
    hl.exec_cmd ("tuned-adm profile balanced")



    -- load clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

  end


  if hostname == "HyprSurface-08" then
    hl.exec_cmd("notify-send 'Loading config:' '" .. hostname .. "'")

    -- load you hypridle laptop profile 
    hl.exec_cmd("hypridle -s ~/.config/hypridle/hypridle-laptop.conf")

  end


end)

