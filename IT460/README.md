# IT 460 Ethical Hacking / Pentest+ labs
Based on https://github.com/Azure/azure-devtestlab/blob/master/samples/ClassroomLabs/Scripts/EthicalHacking/Setup-EthicalHacking.ps1

## To run:
Download Metasploitable3 VMs and put OVA files in %TEMP%

```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot


## Post-Setup tasks
**Desktop**
1. Windows Update + reboot several times
2. background

**KALI VM**
1. Full Install
   - Username/Password: justincase:Password01
2. Configure Network
   - Internal Network
     - IP: 192.168.0.10/24
     - GW: 192.168.0.250
     - DNS: 8.8.8.8
   - Private Network
     - IP: 192.168.38.10/24
     - GW: 
3. Screen Resolution issues
   - Inside the Kali VM, run the following:
```
git clone https://github.com/mimura1133/linux-vm-tools
chmod 0755 linux-vm-tools/kali/2020.x/install.sh
sudo linux-vm-tools/kali/2020.x/install.sh
```
   - Shutdown Kali, then in PowerShell
```Set-VM "Kali Linux" -EnhancedSessionTransportType HvSocket```

**Metasploitable 2**
1. Configure Network
   - Private Network
     - IP: 192.168.38.20/24
     - GW: 192.168.38.250
   - metasploitable2 static IP instructions: https://www.howtoforge.com/community/threads/setting-static-ip-on-ubuntu-8-04-server.25277/

**Metasploitable 3 Ubuntu**
1. Configure Network
   - Private Network
     - IP: 192.168.38.30/24
     - GW: 192.168.38.250
   - Static IP instructions: https://www.unixmen.com/setup-static-ip-ubuntu-14-04/ 

**Metasploitable 3 Windows**
1. Configure Network
   - Private Network
     - IP: 192.168.38.40/24
     - GW: 192.168.38.250
2. Login and ensure devices are discovered properly
3. License the OS?
   - slmgr -rearm to reset the eval period
   - possibly set into runonce key prior to checkpoint of VM?

**DVWA**
1. Install Install Ubuntu desktop - full
```
sudo apt update
sudo apt upgrade
```

2. install docker
`sudo apt install docker.io`

3. Install DVWA
`sudo docker run --restart=always -d -p 80:80 vulnerables/web-dvwa`

tweak DVWA fileinclude
```
sudo docker exec dvwa sed -i 's/allow_url_include = Off/allow_url_include = On/g' /etc/php/7.0/apache2/php.ini 
sudo docker exec dvwa /etc/init.d/apache2 reload
```

5. Install Juice Shop
`sudo docker run --restart=always -d -p 3000:3000 bkimminich/juice-shop`

6. Checkpoint VM and test
```
web browser to http://localhost -- opens dvwa
web browser to http://localhost -- opens Juice shop
```
6. Reconfigure Network - https://linuxize.com/post/how-to-configure-static-ip-address-on-ubuntu-20-04/
   - Private Network
     - IP: 192.168.38.50/24
     - GW: 192.168.38.250

**All VMs**
When finished customizing
```
Get-VM | Stop-VM
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot"
```
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```
