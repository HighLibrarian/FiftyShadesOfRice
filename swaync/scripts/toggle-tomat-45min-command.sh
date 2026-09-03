#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    tomat start --work 45 --break 5 --long-break 15 --sessions 4 --auto-advance "to-break"
else
    tomat stop
fi

swaync-client -cp