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
