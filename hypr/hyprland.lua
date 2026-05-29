-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

require("modules.keybindings")
require("modules.monitors")
require("modules.env")
require("modules.autostart")
require("modules.decorations")
require("modules.animations")
require("modules.windowrules")
require("modules.workspacerules")
require("modules.layout")
require("modules.misc")
require("modules.input")