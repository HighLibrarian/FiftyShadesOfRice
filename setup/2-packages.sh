#!/usr/bin/env bash

YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'


# get a list of all our installed packages
installed=$(dnf list --installed)


## Notes: 
# jq is used to parse the JSON file
# it will extract the package names from the "base" array. 
# The script then iterates over each package name and installs it using dnf


# MARK: RPM
for package in $(jq -r '.rpm_base[]' packages.json); do
  echo -e "${YELLOW}---------------- Installing rpm base package: $package ----------------\n ${NC}"
  sudo dnf install -y "$package"
done



# MARK: Flatpak
for package in $(jq -r '.flatpak_base[]' packages.json); do
  echo -e "${YELLOW}---------------- Installing flatpak package: $package ----------------\n ${NC}"
  flatpak install  "$package" -y
done



# MARK: HYPR
for package in $(jq -r '.hyprland[]' packages.json); do
  echo -e "${BLUE}---------------- Installing Hyprland: $package ----------------\n ${NC}"
  sudo dnf install -y "$package"
done



pipx install waypaper