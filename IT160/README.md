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
1. Login to the template VM and install Windows
2. When finished, use sysprep to generalize the VM
3. Then run 02-MainSetup.ps1 to clone the template
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/02-MainSetup.ps1" -OutFile $env:TEMP\02-MainSetup.ps1
."$env:Temp\02-MainSetup.ps1"
```

# Post cloning
1. Power on each VM and set the Administrator password to Password01
2. Run the scripts for the individual VMs to configure the VMs (manually walk through each script to ensure it works)
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/11-ServerDC1.ps1" -OutFile $env:TEMP\11-ServerDC1.ps1
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/12-ServerDM1.ps1" -OutFile $env:TEMP\12-ServerDM1.ps1
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/13-ServerDM2.ps1" -OutFile $env:TEMP\13-ServerDM2.ps1
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/14-ServerSA1.ps1" -OutFile $env:TEMP\14-ServerSA1.ps1
```
3. Run the remaining setup scripts to capture snapshots
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/20-MainSetup.ps1" -OutFile $env:TEMP\20-MainSetup.ps1
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT160/99-MainSetup.ps1" -OutFile $env:TEMP\99-MainSetup.ps1
```

## Post-Setup tasks
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```
**All VMs**
None
