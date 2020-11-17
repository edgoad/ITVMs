# IT 114 Introduction to IT
This image allows students to install their VMs individually. Multiple OSs are present and more can be added.

## Pre-Setup tasks
Run Windows Update and AV scan prior to installation

## To run open Powershell on VM and run:
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT114/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot


## Post-Setup tasks
Run Windows Update on host Operating system several times with reboots
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```
**All VMs**
None
