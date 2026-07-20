#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    touch /tmp/gamestreaming
    hyprctl output create headless HEADLESS
    hyprctl reload
    hyprctl eval 'hl.monitor({ output = "HEADLESS", mode = "3840x2160", position = "auto", scale = "1" })'
else
    rm -f /tmp/gamestreaming
    hyprctl output remove HEADLESS
fi


swaync-client -cp