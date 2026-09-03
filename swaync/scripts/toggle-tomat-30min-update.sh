#!/bin/sh

if tomat status | jq .tooltip | grep '30.0min'; then
    echo true
else
    echo false
fi