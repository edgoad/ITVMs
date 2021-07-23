#######################################################################
#
# Last script for building Hyper-V environment for IT 160
# Shuts down all VMs and takes snapshots
#
#######################################################################

# Compress / optimize vhds
$vhds = Get-Item -Path "C:\vms\Serv*.vhdx"
Optimize-VHD $vhds -Mode full

Get-VM | Stop-VM 
Get-VM | Set-VM -SmartPagingFilePath D:\
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot" 

# setup rename
#$command = 'powershell -Command "& { rename-computer -newname $( $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
#New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value "powershell c:\Users\public\renamescript.ps1" -PropertyType ExpandString
