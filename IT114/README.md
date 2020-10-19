# IT 114 Introduction to IT
This image allows students to install their VMs individually. Multiple OSs are present and more can be added

## To run open Powershell on VM and run:
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot


## Post-Setup tasks
**All VMs**
When finished customizing
```
Get-VM | Stop-VM
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot"
```