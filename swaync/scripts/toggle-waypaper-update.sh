#!/bin/sh

if pgrep -x waypaper >/dev/null; then
    echo true
else
    echo false
fi