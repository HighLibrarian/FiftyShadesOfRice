#!/bin/bash

# Extract percentage as a number and status using acpi
# We use awk to grab the 4th field (percentage) and 3rd field (status)
battery_output=$(acpi -b)
battery_percentage=$(echo "$battery_output" | awk -F'[, ]+' '{print $4}' | tr -d '%')
battery_status=$(echo "$battery_output" | awk -F'[, ]+' '{print $3}')
battery_dischargetime=$(echo "$battery_output" | awk -F'[, ]+' '{print $5}')




# Define the battery icons for each 10% segment
battery_icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")

# Define the charging icon
charging_icon="󰂄"

# Define time icon
time_icon="󰔟"

# Calculate the index for the icon array (0-9)
# If percentage is 100, index 10 would break, so we cap it at 9
icon_index=$((battery_percentage / 10))
[ "$icon_index" -gt 9 ] && icon_index=9

# Get the corresponding icon
battery_icon=${battery_icons[icon_index]}

# Check if the battery is charging
if [ "$battery_status" = "Charging" ]; 
then
    battery_icon="$charging_icon"

    # Output the battery percentage and icon
    echo "$battery_icon $battery_percentage%"
else
    # Output the battery percentage and icon
    echo "$battery_icon $battery_percentage% | $time_icon $battery_dischargetime"

fi
else



