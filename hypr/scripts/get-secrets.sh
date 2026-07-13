#!/bin/bash

# get secrets from our keyring and store them in env vars
export MQTT_USER="$(secret-tool lookup "mqtt broker" user)" || notify-send -u normal -t 5 "MQTT" "failed to fetch user"
export MQTT_PASS="$(secret-tool lookup "mqtt broker" pass)" || notify-send -u normal -t 5 "MQTT" "failed to fetch password"
export MQTT_HOST="$(secret-tool lookup "mqtt broker" host)" || notify-send -u normal -t 5 "MQTT" "failed to fetch host"
export MQTT_PORT="$(secret-tool lookup "mqtt broker" port)" || notify-send -u normal -t 5 "MQTT" "failed to fetch port"
notify-send -u normal -t 5 "MQTT"  "Loaded"