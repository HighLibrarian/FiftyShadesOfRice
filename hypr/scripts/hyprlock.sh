#!/usr/bin/env bash
~/.config/mqtt/send-mqtt-message.sh "hyprstation-01/session_state" "Locked";
hyprlock
~/.config/mqtt/send-mqtt-message.sh "hyprstation-01/session_state" "Unlocked";
