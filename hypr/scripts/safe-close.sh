#!/usr/bin/env bash
focused=$(hyprctl -j activewindow)

is_protected=$(echo "$focused" | jq -r '.tags[]?' | grep -qx "protected" && echo yes || echo no)

if [[ "$is_protected" == "yes" ]]; then
    if zenity --question --text="This window is protected. Close it?"; then
        hyprctl dispatch killactive
    fi
else
    hyprctl dispatch killactive
fi