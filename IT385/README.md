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
3. Update and upgrade Ubuntu packages
```
sudo apt update
sudo apt install python3 python3-pip telnet ftp git
sudo apt upgrade
sudo apt autoremove
```
3. Append the following to /etc/ssh/ssh_config (due to Cisco/OpenSSH issue)
```
KexAlgorithms +diffie-hellman-group-exchange-sha1
Ciphers +3des-cbc
```
4. Ensure you can ssh cisco@192.168.0.11 and cisco@192.168.0.12
5. Setup Enhanced session? https://medium.com/@francescotonini/how-to-install-ubuntu-20-04-on-hyper-v-with-enhanced-session-b20a269a5fa7
```
wget https://raw.githubusercontent.com/Microsoft/linux-vm-tools/master/ubuntu/18.04/install.sh
sudo chmod +x install.sh
sudo ./install.sh
```
5. Install features and cleanup
```
rm .ssh/known_hosts
sudo history -c
history -c
```
6. Shutdown template


**PostTemplates**
When all templates are finished, run the following
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/02-MainSetup.ps1" -OutFile $env:TEMP\02-MainSetup.ps1
."$env:Temp\02-MainSetup.ps1"
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
systemctl start sshd
history -c
```

**All VMs**
When finished customizing, run the following to snapshot VMs and prompt for rename on boot
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/99-MainSetup.ps1" -OutFile $env:TEMP\99-MainSetup.ps1
."$env:Temp\99-MainSetup.ps1"
```
