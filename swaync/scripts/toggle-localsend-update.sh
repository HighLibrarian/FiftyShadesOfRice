#!/bin/sh

if flatpak ps | grep -q "localsend"; then
    echo true
else
    echo false
fi