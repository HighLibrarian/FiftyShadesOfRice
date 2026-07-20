#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    swaync-client -cp &
    steam -pipewire -start steam://open/bigpicture &
else
    pkill -x steam
fi