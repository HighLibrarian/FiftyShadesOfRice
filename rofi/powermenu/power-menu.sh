#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# Current Theme
dir="$HOME/.config/rofi/powermenu"
theme='power-menu'

# CMDs
lastlogin="`last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7`"
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostname`

# Helpers
is_hyprland="${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}"

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

# Options
hibernate='󰤄' # for longer breaks
suspend='󱖐'   # for short breaks.
shutdown='󰐥'
reboot='󰜉'
sessionrestart=''   # restart the hyprland session
lock='󱅞'
logout='󰍃'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-me-select-entry '' \
		-me-accept-entry MousePrimary \
		-p "  $USER@$host" \
		-mesg "    Last Login: $lastlogin | 󰔛  Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$shutdown\n$reboot\n$lock\n$logout\n$sessionrestart\n$suspend\n$hibernate" | rofi_cmd

}

# Execute Command
run_cmd() {
	if [[ $1 == '--shutdown' ]]; then
		if has_cmd hyprshutdown && [[ "$is_hyprland" =~ [Hh]yprland ]]; then
			hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'
		else
			systemctl poweroff
		fi
	elif [[ $1 == '--reboot' ]]; then
		if has_cmd hyprshutdown && [[ "$is_hyprland" =~ [Hh]yprland ]]; then
			hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot'
		else
			systemctl reboot
		fi
	elif [[ $1 == '--hibernate' ]]; then
		systemctl hibernate
	elif [[ $1 == '--suspend' ]]; then
		mpc -q pause
		amixer set Master mute
		systemctl suspend
	elif [[ $1 == '--logout' ]]; then
		if has_cmd hyprshutdown && [[ "$is_hyprland" =~ [Hh]yprland ]]; then
			hyprshutdown
		elif has_cmd loginctl; then
			loginctl terminate-user "$USER"
		fi
	elif [[ $1 == '--sessionrestart' ]]; then
		if has_cmd hyprctl && [[ "$is_hyprland" =~ [Hh]yprland ]]; then
			hyprctl dispatch exit
		fi
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $hibernate)
		run_cmd --hibernate
        ;;
		$sessionrestart)
		run_cmd --sessionrestart
				;;
    $lock)
		if has_cmd hyprlock && [[ "$is_hyprland" =~ [Hh]yprland ]]; then
			hyprlock
		elif [[ -x '/usr/bin/betterlockscreen' ]]; then
			betterlockscreen -l
		elif [[ -x '/usr/bin/i3lock' ]]; then
			i3lock
		fi
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
