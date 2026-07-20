#!/bin/sh

state="${SWAYNC_TOGGLE_STATE:-false}"

if [ "$state" = "true" ]; then
    tuned-adm profile balanced
else
    tuned-adm profile throughput-performance
fi