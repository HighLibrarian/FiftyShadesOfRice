#!/usr/bin/env bash

dir="$HOME/.config/rofi/launcher-mini"
theme="launcher-mini"

obsidian=""
files="󰉋"
code="󰨞"

rofi_cmd() {
    rofi -dmenu \
        -format i \
        -theme "$dir/$theme.rasi"
}

chosen="$(
    printf '%s\n' "$obsidian" "$files" "$code" | rofi_cmd
)"

case "$chosen" in
    0) ~/AppImages/obsidian.appimage >/dev/null 2>&1 & ;;
    1) nautilus --new-window >/dev/null 2>&1 & ;;
    2) code >/dev/null 2>&1 & ;;
esac