# IT 385 Automation / Ansible

## To run:
1. Manually download the CSR ISO from https://software.cisco.com/download/home/284364978/type/282046477/release/3.11.2S to c:\VMs
2. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot

## Post-Setup tasks
**CSR**
1. Install CSR1000V
2. Enter the following to configure each CSR (change name and IP as appropriate)
```
en
conf t
hostname IT385-CSR1
ip domain name ccna.local
username cisco privilege 15 password 0 cisco
int g1
ip add 192.168.0.11 255.255.255.0
no shut
description Internal network
line vty 0 15
login local
transport input ssh
crypto key generate rsa modulus 1024
do wr mem
```
3. Shutdown template

**UbuntuTemplate**
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
wget https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/11-UbuntuTemplate.sh
chmod +x 11-UbuntuTemplate.sh
./11-UbuntuTemplate.sh
```
4. Ensure you can ssh cisco@192.168.0.11 and cisco@192.168.0.12
5. Shutdown template


**PostTemplates**
When all templates are finished, run the following
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/20-MainSetup.ps1" -OutFile $env:TEMP\20-MainSetup.ps1
."$env:Temp\20-MainSetup.ps1"
```

**Linux VMs**
1. Login and change background
2. Configure networking
3. Run the following on each to change names and generate new SSH host keys
```
sudo su -
hostnamectl set-hostname ansible
nano /etc/hosts
rm -r /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
history -c
```

**All VMs**
When finished customizing, run the following to snapshot VMs and prompt for rename on boot
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/99-MainSetup.ps1" -OutFile $env:TEMP\99-MainSetup.ps1
."$env:Temp\99-MainSetup.ps1"
```
