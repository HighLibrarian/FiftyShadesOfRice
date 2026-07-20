#!/usr/bin/env bash
wallpaper=$(
  awww query |
  awk -F'image: ' '/^: DP-3:/ {print $2; exit}'
)
sleep 2

cp "$wallpaper" ~/.cache/rofi-bg.png
/home/bdw/.local/bin/iris "$wallpaper" --dark 1