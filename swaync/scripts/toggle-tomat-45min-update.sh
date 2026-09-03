#!/bin/sh

if tomat status | jq .tooltip | grep Work.*45.0min'; then
    echo true
else
    echo false
fi