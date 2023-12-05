#######################################################################
#
# Last script for building Hyper-V environment for IT 160
# Shuts down all VMs and takes snapshots
#
#######################################################################

# Shutdown VMs
Get-VM | Stop-VM 

# Compress / optimize vhds
$vhds = Get-Item -Path "C:\BaseVMs\Serv*.vhdx"
Optimize-VHD $vhds -Mode full

# Set initial snapshot
Get-VM | Checkpoint-VM -SnapshotName "InitialConfig" 



# Reset for student created VMs
New-Item -ItemType Directory -Path c:\VMs -Force
# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "c:\VMs"
Set-VMHost -VirtualMachinePath "c:\VMs"