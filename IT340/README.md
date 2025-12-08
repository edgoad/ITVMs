# IT 340 Opnsense

## To run:
1. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT340/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

2. Power on and install Ubuntu VMs
Name according to the VM name
Student / Password01 for login credentials (autologon?)
Change backgrounds for easy identification
Install services?



## Remaining setup
All remaining install and setup will be performed by the student.


**All VMs**
When finished customizing, run the following
```
Get-VM | Stop-VM
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot"
```
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```


