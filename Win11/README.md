# Win11 PowerShell
Sets up Host machine, installs Hyper-V, and configures several VMs
Does not install OS on VMs, assumes students will do this.

## Pre-Setup tasks
Run Windows Update and AV scan on host prior to installation

## To run open Powershell on VM and run:
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/Win11/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot

## Install Win11
During install, when prompted to for a MS Sign in press SHIFT + F10
then type `OOBE\BYPASSNRO`
This will reboot, then allow for  alocal account

Once installed, run the following to licence it
```
DISM /Online /Set-Edition:Enterprise /ProductKey:NPPR9-FWDCX-D2C8J-H872K-2YT43 /AcceptEula
```


## Post-Setup tasks
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```
**All VMs**
None
