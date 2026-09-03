#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    tomat start --work 30 --break 5 --long-break 15 --sessions 4
else
    tomat stop
fi

swaync-client -cp