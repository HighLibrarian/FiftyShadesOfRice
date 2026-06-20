#!/usr/bin/env bash

if hyprctl activewindow | grep -q "tags:.*protected"; then
    notify-send "Protected Window" "Use SUPER+SHIFT+Q to force close." --icon=dialog-warning
    exit 1
fi

hyprctl dispatch "hl.dsp.window.close()"