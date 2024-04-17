#!/bin/bash

# Install packages after installing base Debian with no GUI

# todo: icons, confs, wm, obsidian auto

# Check if script is run as root:
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
  exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

# Update packages list and update system:
apt update
apt upgrade -y

# Xorg display server installation:
apt install -y xserver-xorg x11-xserver-utils x11-utils xinit picom 

# Essential packages:
apt install -y build-essential unzip wget 
apt install -y curl tree whois gpg apt-transport-https debian-archive-keyring udns-utils
apt install -y menu lxpolkit dbus-x11 

# Audio:
apt install -y pipewire wireplumber pavucontrol
sudo -u $username systemctl --user enable wireplumber.service

# Network: 
apt install -y network-manager nm-tray

# Pref Apps:
apt install -y vim neofetch figlet rofi feh
apt install -y flameshot strawberry libreoffice thunderbird galculator imagemagick cpu-x 

# File manager:
apt install -y thunar 

# Terminal emulator:
apt install -y kitty

# Browser:
apt install -y firefox-esr 

curl -fsSL https://packagecloud.io/filips/FirefoxPWA/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/firefoxpwa-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/firefoxpwa-keyring.gpg] https://packagecloud.io/filips/FirefoxPWA/any any main" | sudo tee /etc/apt/sources.list.d/firefoxpwa.list > /dev/null
apt install -y firefoxpwa

# Fonts:
apt install -y fonts-recommended fonts-font-awesome
fc-cache -vf

# Laptop essentials: 
# apt install -y xbacklight acpi acpid xfce4-power-manager
# systemctl enable acpid

# Display manager:
apt install -y lightdm light-locker
systemctl enable lightdm
systemctl set-default graphical.target

# XFCE4 Minimal:
# apt install -y xfce4 xfce4-goodies

# Openbox packages:
apt install openbox obconf obmenu tint2 
apt install dunst libnotify-bin lxappearance 