# IT 102 Python

## To run:
1. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT102/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot

## Post-Setup tasks

**UbuntuVM**
1. Install Ubuntu Linux on Template with Static IP
   - username/password - justincase/Password01
2. Configure Network
   - Internal Network
     - IP: 192.168.0.100/24
     - GW: 192.168.0.250
     - DNS: 8.8.8.8
3. Download and run Template setup script (NOTE: This may reboot and re-run to complete successfully)
```
sudo su -
wget https://raw.githubusercontent.com/edgoad/ITVMs/master/IT102/11-UbuntuTemplate.sh
chmod +x 11-UbuntuTemplate.sh
./11-UbuntuTemplate.sh
```
4. Run the following as justincase
```
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'code.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'libreoffice-writer.desktop', 'snap-store_ubuntu-software.desktop', 'yelp.desktop']"
```
5. Shutdown template
6. Run the following in PowerShell to enable Enhanced Session Mode
```
Get-VM ubuntu* | Set-VM -EnhancedSessionTransportType HvSocket
```


**All VMs**
When finished customizing, run the following to snapshot VMs and prompt for rename on boot
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT102/99-MainSetup.ps1" -OutFile $env:TEMP\99-MainSetup.ps1
."$env:Temp\99-MainSetup.ps1"
```


# IT 102 Python alt
Alternate using Ubuntu VM instead of Windows

1. Create Uubntu 24.04 LTS system
2. SSH from remote system to template
3. Install GUI, run the following commands and reboot
```
sudo apt update
sudo apt install ubuntu-desktop -y
# sudo apt install xubuntu-desktop -y
sudo systemctl set-default graphical.target
sudo reboot
```
4. Reconnect via SSH, Install xrdp
```
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp
sudo systemctl status xrdp
```
5. Download and run Template setup script (NOTE: This may reboot and re-run to complete successfully). DONT install XRDP
```
sudo su -
wget https://raw.githubusercontent.com/edgoad/ITVMs/master/IT102/11-UbuntuTemplate.sh
chmod +x 11-UbuntuTemplate.sh
./11-UbuntuTemplate.sh
```
6. Run the following as justincase
```
echo 'export GNOME_SHELL_SESSION_MODE=ubuntu' > ~/.xsession
echo 'export XDG_CURRENT_DESKTOP=ubuntu:GNOME' >> ~/.xsession
echo 'exec gnome-session' >> ~/.xsession
```
7. Shutdown template