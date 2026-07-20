#!/bin/sh

if pgrep -x steam >/dev/null; then
    echo true
else
    echo false
fi