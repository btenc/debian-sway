#!/bin/bash

# Install packages after installing base Debian with no GUI

# todo: icons, confs

# Check if script is run as root:
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
  exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/Pictures
mkdir -p /home/$username/Pictures/wallpapers
mkdir -p /home/$username/Documents
mkdir -p /home/$username/Videos
mkdir -p /home/$username/Music
mkdir -p /home/$username/appimages
mkdir -p /home/$username/deb
mkdir -p /home/$username/Downloads
mkdir -p /home/$username/dev
mkdir -p /home/$username/dev/repos
mkdir -p /home/$username/dev/scripts
mkdir -p /home/$username/Disks
cp -R dotconfig/* /home/$username/.config/
cp -R deb/* /home/$username/deb/
cp bg.jpg /home/$username/Pictures/wallpapers/
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# Update packages list and update system:
apt update
apt upgrade -y

# Xorg display server installation:
apt install -y xserver-xorg x11-xserver-utils x11-utils xinit 

# Essential packages:
apt install -y build-essential eject zip unzip wget whois apt-transport-https dirmngr curl ssh traceroute iw acl ufw
apt install -y tree gpg debian-archive-keyring udns-utils
apt install -y lshw lxpolkit dbus-x11 
apt install -y xfce4-power-manager acpi 

# Audio:
apt install -y pipewire wireplumber pavucontrol
sudo -u $username systemctl --user enable wireplumber.service

# Network: 
apt install -y network-manager

# Pref Apps:
apt install -y vim ranger htop neofetch figlet parted gparted qalc 
apt install -y vlc feh audacity gimp flameshot strawberry libreoffice thunderbird qalculate-gtk imagemagick
apt install -y /home/$username/deb/

# File manager:
apt install -y thunar thunar-archive-plugin thunar-gtkhash thunar-media-tags-plugin thunar-volman

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
# apt install -y xbacklight acpid
# systemctl enable acpid

# Display manager:
apt install -y lightdm light-locker
systemctl enable lightdm
systemctl set-default graphical.target

# XFCE4 Minimal:
# apt install -y xfce4 xfce4-goodies

# Openbox packages:
apt install -y openbox obconf tint2 menu rofi picom dunst lxappearance 

#mkdir -p ~/.config/openbox
#cp -a /etc/xdg/openbox/ ~/.config/

echo "You can now reboot."