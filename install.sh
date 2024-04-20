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
echo "apt-log will be located at /home/$username"

# Home directories to be created
directories=(.config ./config/sway .config/waybar .config/wofi .icons .themes Pictures/wallpapers Documents Videos Music appimages deb Downloads dev/repos dev/scripts disks)

echo "Creating directories for user $username..."
for dir in "${directories[@]}"; do
  mkdir -p "$user_home/$dir" || { echo "Failed to create $dir, skipping..."; }
done

echo "Copying configuration and necessary files..."
cp -R dotconfig/* "$user_home/.config/" || echo "Failed to copy configuration files to .config, skipping..."
chmod +x "$user_home/.config/sway/audio.sh" || echo "Failed to make scripts executable, skipping..."
chmod +x "$user_home/.config/sway/exit.sh" || echo "Failed to make scripts executable, skipping..."
chmod +x "$user_home/.config/sway/loack_screen.sh" || echo "Failed to make scripts executable, skipping..."

cp -R dotthemes/* "$user_home/.themes/" || echo "Failed to copy themes, skipping..."
cp -R doticons/* "$user_home/.icons/" || echo "Failed to copy icons, skipping..."
cp -R deb/* "$user_home/deb/" || echo "Failed to copy .deb files, skipping..."

# Check if bg.jpg exists before copying
if [ -f "bg.jpg" ]; then
    cp wallpaper.jpg "$user_home/.config/sway/wallpaper.jpg" || echo "Failed to copy wallpaper.jpg"
else
    echo "Warning: 'wallpaper.jpg' not found, skipping..."
fi

chown -R $username:$username "$user_home" || echo "Failed to change ownership to $username"

# System update:
echo "Updating system packages..."
apt update &>> "${user_home}/apt-log.txt" && apt upgrade -y &>> "${user_home}/apt-log.txt"

# Installation of various packages
echo "Installing base system utilities..."
apt install -y build-essential eject zip unzip parted wget whois lshw apt-transport-https dirmngr curl ssh traceroute iw acl ufw acpi tree gpg debian-archive-keyring udns-utils &>> "${user_home}/apt-log.txt"

echo "Installing additional utilities..."
apt install -y xfce4-power-manager lxappearance &>> "${user_home}/apt-log.txt"

echo "Installing audio management packages..."
apt install -y pipewire wireplumber pavucontrol &>> "${user_home}/apt-log.txt"

echo "Installing preferred applications..."
echo "    CLI applications..."
apt install -y vim zoxide ranger htop neofetch figlet qalc zathura &>> "${user_home}/apt-log.txt"
echo "    GUI applications..."
apt install -y clapper clipman audacity gparted gimp flameshot strawberry libreoffice thunderbird qalculate-gtk imagemagick &>> "${user_home}/apt-log.txt"

echo "Installing file manager and related plugins..."
apt install -y pcmanfm &>> "${user_home}/apt-log.txt"

echo "Installing terminal..."
apt install -y foot &>> "${user_home}/apt-log.txt"

echo "Installing browser and PWA functionality..."
apt install -y firefox-esr &>> "${user_home}/apt-log.txt"
if curl -fsSL https://packagecloud.io/filips/FirefoxPWA/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/firefoxpwa-keyring.gpg > /dev/null; then
  echo "deb [signed-by=/usr/share/keyrings/firefoxpwa-keyring.gpg] https://packagecloud.io/filips/FirefoxPWA/any any main" | sudo tee /etc/apt/sources.list.d/firefoxpwa.list > /dev/null
  apt update &>> "${user_home}/apt-log.txt" && apt install -y firefoxpwa &>> "${user_home}/apt-log.txt" || { echo "Firefox PWA installation failed.";}
else
  echo "Failed to download or process the GPG key for Firefox PWA."
fi

echo "Installing fonts..."
apt install -y fonts-recommended fonts-font-awesome &>> "${user_home}/apt-log.txt"
fc-cache -vf &>> "${user_home}/apt-log.txt"

echo "Setting up display manager..."
apt install -y sddm &>> "${user_home}/apt-log.txt"
systemctl enable sddm || echo "Failed to enable display manager"
systemctl set-default graphical.target || echo "Failed to set default graphical target"

echo "Installing window management tools..."
apt install -y sway swaybg swayimg swayidle swayimg swaylock sway-notification-center waybar wofi light xdg-desktop-portal-wlr &>> "${user_home}/apt-log.txt"

echo "Installing local .deb packages..."
deb_dir="$user_home/deb"
if compgen -G "${deb_dir}/*.deb" > /dev/null; then
  apt install -y "$deb_dir"/*.deb &>> "${user_home}/apt-log.txt"
else
  echo "No .deb files found in $deb_dir to install."
fi

echo "Enabling wireplumber service..."
sudo -u $username XDG_RUNTIME_DIR=/run/user/$(id -u $username) systemctl --user enable wireplumber.service || echo "Failed to enable wireplumber service for $username"

apt autopurge &>> "${user_home}/apt-log.txt"

echo "Setup complete. You can now reboot."
