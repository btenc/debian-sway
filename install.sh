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
directories=(.config ./config/sway .config/waybar .config/wofi .icons .themes pictures/wallpapers pictures/screenshots documents videos music appimages deb downloads dev/repos dev/scripts disks)

echo "Creating directories for user $username..."
for dir in "${directories[@]}"; do
  mkdir -p "$user_home/$dir" || { echo "Failed to create $dir, skipping..."; }
done

echo "Copying configuration and necessary files..."
cp -R dotconfig/* "$user_home/.config/" || echo "Failed to copy configuration files to .config, skipping..."
for script in "$user_home/.config/sway"/*.sh; do
    chmod +x "$script" || echo "Failed to make $script executable, skipping..."
done

cp -R dotthemes/* "$user_home/.themes/" || echo "Failed to copy themes, skipping..."
cp -R doticons/* "$user_home/.icons/" || echo "Failed to copy icons, skipping..."
cp -R deb/* "$user_home/deb/" || echo "Failed to copy .deb files, skipping..."
cp dotbash_profile "$user_home/.bash_profile" || echo "Failed to copy bash profile, skipping..."

# Check if wallpaper.jpg exists before copying
if [ -f "wallpaper.jpg" ]; then
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
apt install -y build-essential eject dosfstools zip unzip parted wget whois lshw apt-transport-https dirmngr curl ssh traceroute iw acl ufw tree gpg debian-archive-keyring udns-utils libnotify-bin &>> "${user_home}/apt-log.txt"

echo "Installing additional utilities..."
apt install -y dialog mtools dosfstools avahi-daemon acpi acpid gvfs-backends network-manager &>> "${user_home}/apt-log.txt"
systemctl enable avahi-daemon || echo "Failed to enable avahi daemon"
systemctl enable acpid || echo "Failed to enable acpid"

echo "Installing audio management packages..."
apt install -y pipewire wireplumber pavucontrol pamixer &>> "${user_home}/apt-log.txt"

echo "Installing preferred applications..."
echo "  CLI applications..."
apt install -y vim zoxide ranger cmus htop neofetch figlet rsync wireguard qalc zathura scrot &>> "${user_home}/apt-log.txt"
#todo: add scrot macro: scrot ~/pictures/screenshots/%m-%d-%Y_%I:%M:%S.png scrot -s -f ~/pictures/screenshots/%m-%d-%Y_%I:%M:%S.png
echo "  GUI applications..."
apt install -y mpv clipman audacity gparted gimp strawberry libreoffice thunderbird qalculate-gtk &>> "${user_home}/apt-log.txt"

echo "Installing file manager..."
apt install -y thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman &>> "${user_home}/apt-log.txt"

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

echo "Installing Flatpak and adding Flathub repository..."
apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || echo "Failed to add Flathub repository"
echo "Installing Flatpak apps from Flathub..."
flatpak install -y flathub md.obsidian.Obsidian || echo "Failed to install Obsidian from flathub"
ln -s /var/lib/flatpak/exports/bin/md.obsidian.Obsidian /usr/bin/Obsidian || echo "Failed to create symlink for Obsidian"
#If you like runescape...
#flatpak install -y flathub com.adamcake.Bolt || echo "Failed to install Bolt from flathub"
#ln -s /var/lib/flatpak/exports/bin/com.adamcake.Bolt /usr/bin/Bolt || echo "Failed to create symlink for Bolt"

echo "Installing fonts..."
apt install -y fonts-recommended fonts-font-awesome &>> "${user_home}/apt-log.txt"
fc-cache -vf &>> "${user_home}/apt-log.txt"

#echo "Setting up display manager..."
#apt install -y greetd &>> "${user_home}/apt-log.txt"
#systemctl enable greetd || echo "Failed to enable display manager"
#systemctl set-default graphical.target || echo "Failed to set default graphical target"

echo "Installing window management tools..."
apt install -y sway swaybg swayimg swayidle swayimg swaylock sway-notification-center waybar wofi light xwayland xdg-desktop-portal-wlr &>> "${user_home}/apt-log.txt"
apt install -y libglib2.0-bin gnome-themes-extra &>> "${user_home}/apt-log.txt"

echo "Installing local .deb packages..."
deb_dir="$user_home/deb"
if compgen -G "${deb_dir}/*.deb" > /dev/null; then
  apt install -y "$deb_dir"/*.deb &>> "${user_home}/apt-log.txt"
else
  echo "No .deb files found in $deb_dir to install."
fi

echo "Enabling wireplumber service..."
sudo -u $username XDG_RUNTIME_DIR=/run/user/$(id -u $username) systemctl --user enable wireplumber.service || echo "Failed to enable wireplumber service for $username"

apt autoremove &>> "${user_home}/apt-log.txt"

echo "Setup complete. You can now reboot."
