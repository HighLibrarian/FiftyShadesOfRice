#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    /usr/bin/wpctl set-mute 61 1
else
    /usr/bin/wpctl set-mute 61 0
fi