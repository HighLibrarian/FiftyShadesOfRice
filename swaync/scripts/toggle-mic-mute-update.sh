#!/bin/sh

if /usr/bin/wpctl get-volume 61 | grep -q "\[MUTED\]"; then
    echo true
else
    echo false
fi