# IT 160 / IT 240 / IT 245 Windows Server 1, 2, 3

## Pre-Setup tasks
Run Windows Update and AV scan on host prior to installation

## To run open Powershell on VM and run:
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot

# After first script
Login to the template VM and install Windows
When finished, use sysprep to generalize the VM
Then run 02-MainSetup.ps1 to clone the template

# Post cloning
Power on each VM and set the Administrator password to Password01
Run the scripts for the individual VMs to configure the VMs
Run the remaining setup scripts to capture snapshots

## Post-Setup tasks
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```
**All VMs**
None