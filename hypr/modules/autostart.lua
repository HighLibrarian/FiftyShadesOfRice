---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  hl.exec_cmd("waybar") -- our top bar
  hl.exec_cmd("swaync") -- notifications
  hl.exec_cmd("awww-daemon") -- wallpaper service
  hl.exec_cmd("hypridle") -- idle manager that triggers hyprlock when needed
end
)
