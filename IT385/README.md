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
**FedoraTemplate**
1. Install Fedora Linux on Template with Static IP
   - username/password - justincase/Password01
2. Configure Network
   - Internal Network
     - IP: 192.168.0.100/24
     - GW: 192.168.0.250
     - DNS: 8.8.8.8
3. Shutdown template

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
crypto key generate rsa
do wr mem
```
3. Shutdown template

**PostTemplates**
When all templates are finished, run the following
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/02-MainSetup.ps1" -OutFile $env:TEMP\02-MainSetup.ps1
."$env:Temp\02-MainSetup.ps1"
```


**All VMs**
1. Login to each machine and change its name
2. Configure Network
3. When finished customizing, run the following to snapshot VMs
```
Get-VM | Stop-VM
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot"
```
4. Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```