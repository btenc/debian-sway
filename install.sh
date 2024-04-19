#!/bin/bash

# Install packages after installing base Debian with no GUI

# Ensure the script is run as root:
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run 'sudo ./install.sh'"
  exit 1
fi

# Verify user 1000 exists
if ! id "1000" &>/dev/null; then
  echo "User with ID 1000 does not exist, please create this user or modify the script for a different user ID."
  exit 1
fi

username=$(id -u -n 1000)
user_home="/home/$username"

# Home directories to be created
directories=(.config Pictures/wallpapers Documents Videos Music appimages deb Downloads dev/repos dev/scripts disks)

echo "Creating directories for user $username..."
for dir in "${directories[@]}"; do
  mkdir -p "$user_home/$dir" || { echo "Failed to create $dir"; exit 1; }
done

echo "Copying configuration and necessary files..."
cp -R dotconfig/* "$user_home/.config/" || echo "Failed to copy configuration files to .config"
cp -R deb/* "$user_home/deb/" || echo "Failed to copy .deb files"

# Check if bg.jpg exists before copying
if [ -f "bg.jpg" ]; then
    cp bg.jpg "$user_home/Pictures/wallpapers/" || echo "Failed to copy bg.jpg"
else
    echo "Warning: 'bg.jpg' not found, skipping..."
fi

mv user-dirs.dirs "$user_home/.config" || echo "Failed to move user-dirs.dirs file"
chown -R $username:$username "$user_home" || echo "Failed to change ownership to $username"

# System update:
echo "Updating system packages..."
apt update &> ~/apt-log.txt && apt upgrade -y &> ~/apt-log.txt

# Installation of various packages
echo "Installing base system utilities..."
apt install -y build-essential eject zip unzip parted wget whois lshw apt-transport-https dirmngr curl ssh traceroute iw acl ufw acpi tree gpg debian-archive-keyring udns-utils &> ~/apt-log.txt

echo "Installing additional utilities..."
apt install -y lxpolkit xfce4-power-manager arandr network-manager &> ~/apt-log.txt

echo "Installing Xorg display server..."
apt install -y xserver-xorg x11-xserver-utils x11-utils xinit dbus-x11 &> ~/apt-log.txt

echo "Installing audio management packages..."
apt install -y pipewire wireplumber pavucontrol &> ~/apt-log.txt
sudo -u $username systemctl --user enable wireplumber.service || echo "Failed to enable wireplumber service for $username"

echo "Installing preferred applications..."
apt install -y vim zoxide ranger htop neofetch figlet qalc &> ~/apt-log.txt
apt install -y vlc feh audacity gparted gimp flameshot strawberry libreoffice thunderbird qalculate-gtk imagemagick &> ~/apt-log.txt

echo "Installing file manager and related plugins..."
apt install -y thunar thunar-archive-plugin thunar-gtkhash thunar-media-tags-plugin thunar-volman &> ~/apt-log.txt

echo "Installing terminal..."
apt install -y kitty &> ~/apt-log.txt

echo "Installing browser and PWA functionality..."
apt install -y firefox-esr &> ~/apt-log.txt
if curl -fsSL https://packagecloud.io/filips/FirefoxPWA/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/firefoxpwa-keyring.gpg > /dev/null; then
  echo "deb [signed-by=/usr/share/keyrings/firefoxpwa-keyring.gpg] https://packagecloud.io/filips/FirefoxPWA/any any main" | sudo tee /etc/apt/sources.list.d/firefoxpwa.list > /dev/null
  apt update &> ~/apt-log.txt && apt install -y firefoxpwa &> ~/apt-log.txt || { echo "Firefox PWA installation failed.";}
else
  echo "Failed to download or process the GPG key for Firefox PWA."
fi

echo "Installing fonts..."
apt install -y fonts-recommended fonts-font-awesome &> ~/apt-log.txt
fc-cache -vf &> ~/apt-log.txt

echo "Setting up display manager..."
apt install -y lightdm light-locker &> ~/apt-log.txt
systemctl enable lightdm &> ~/apt-log.txt
systemctl set-default graphical.target &> ~/apt-log.txt

echo "Installing window management tools..."
apt install -y openbox obconf tint2 menu rofi picom dunst lxappearance &> ~/apt-log.txt

echo "Installing local .deb packages..."
deb_dir="$user_home/deb"
if compgen -G "${deb_dir}/*.deb" > /dev/null; then
  apt install -y "$deb_dir"/*.deb &> ~/apt-log.txt
else
  echo "No .deb files found in $deb_dir to install."
fi

apt autopurge &> ~/apt-log.txt

echo "Setup complete. You can now reboot."
