#!/bin/sh

if tuned-adm active 2>/dev/null | grep -q "balanced"; then
    echo true
else
    echo false
fi