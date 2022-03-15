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
apt install -y curl wget python3 python3-pip telnet ftp git openssh-server linux-tools-virtual linux-cloud-tools-virtual xrdp apt-transport-https
apt upgrade -y
apt autoremove -y
snap install postman

#install VSCode
logger -t devvm "Installing VSCode: $?"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -y code
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
