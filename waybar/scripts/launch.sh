#!/bin/bash
pkill waybar
pkill swaync
waybar &
swaync &
swaync-client -t -sw &
notify-send "Your momma" "Is a nice lady" &