#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    swaync-client -cp &
    flatpak run org.localsend.localsend_app
else
    flatpak kill org.localsend.localsend_app
fi