#!/usr/bin/env bash


HOSTNAME="HyprStation-01"
hostnamectl set-hostname $HOSTNAME

YELLOW='\033[1;33m'
NC='\033[0m'

# Enable third party repositories
echo -e "${YELLOW}---------------- Enabling third party repositories... ----------------\n ${NC}"
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


# enable some COPR repositories for additional software
echo -e "${YELLOW}---------------- Enabling COPR repositories for additional software... ----------------\n ${NC}"

# COPR for hyprland and tools
sudo dnf copr enable nett00n/hyprland -y

# COPR for awwww
sudo dnf copr enable scottames/awww


## COPR for waypaper
copr enable lionheartp/Hyprland




# Enable flathub repository
echo -e "${YELLOW}---------------- Enabling Flathub repository... ----------------\n ${NC}"
Flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo




# install fuse for app image support
echo -e "${YELLOW}---------------- Installing fuse for AppImage support... ----------------\n ${NC}"
sudo dnf install -y fuse-libs





# update + synchronize the group definition
echo -e "${YELLOW}---------------- Updating and synchronizing the group definition... ----------------\n ${NC}"
sudo dnf group upgrade core -y

# install missing base packages
echo -e "${YELLOW}---------------- Installing missing base packages... ----------------\n ${NC}"
dnf4 group install core -y


# install updates for our system
echo -e "${YELLOW}---------------- Installing updates for our system... ----------------\n ${NC}"
sudo dnf update -y


# install media codecs to get proper multimedia support
echo -e "${YELLOW}---------------- Installing media codecs to get proper multimedia support... ----------------\n ${NC}"
sudo dnf4 group install multimedia -y

# Switch to full FFMPEG.
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y 

# Installs gstreamer components. Required if you use Gnome Videos and other dependent applications.
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y 

# Installs useful Sound and Video complementary packages.
sudo dnf group install -y sound-and-video 


# Disable waiting for network before showing login screen
echo -e "${YELLOW}---------------- Disabling waiting for network before showing login screen... ----------------\n ${NC}"
sudo systemctl disable NetworkManager-wait-online.service