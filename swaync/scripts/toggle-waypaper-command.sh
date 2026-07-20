#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    swaync-client -cp &
    "$HOME/.local/bin/waypaper" &
else
    pkill -x waypaper
fi