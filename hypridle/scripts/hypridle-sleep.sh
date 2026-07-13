#!/bin/bash
balancedpower=tuned-adm active | grep -q "balanced" && echo true || echo false

if [ "$balancedpower" = "true" ]; then
    systemctl suspend
fi