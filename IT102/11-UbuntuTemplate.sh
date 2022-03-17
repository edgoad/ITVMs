#!/bin/bash

###############################################################################
# Use HWE kernel packages
#
HWE=""

# Confirm running as Root
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Change hostname
echo "ubuntu" > /etc/hostname
hostnamectl set-hostname ubuntu

# Install / upgrade packages
apt update
apt install -y curl wget python3 python3-pip telnet ftp git apt-transport-https
apt upgrade -y
apt autoremove -y
snap install postman

#install VSCode
logger -t devvm "Installing VSCode: $?"
apt-get install wget gpg -y
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
apt install apt-transport-https -y
apt update
apt install code -y
logger -t devvm "VSCode Installed: $?"
logger -t devvm "Success"

# Setup favorites
echo
echo
echo "*********************************************"
echo "*********************************************"
echo "** Run the following as justincase "
echo "gsettings set org.gnome.desktop.session idle-delay 0"
echo "gsettings set org.gnome.shell favorite-apps \"['firefox.desktop', 'code.desktop', 'org.gnome.Terminal.desktop', 'postman_postman.desktop', 'org.gnome.Nautilus.desktop', 'libreoffice-writer.desktop', 'snap-store_ubuntu-software.desktop', 'yelp.desktop']\""
echo "*********************************************"
echo "*********************************************"

# Clean up
rm ~/*.sh
history -c
