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
Get-VM | Checkpoint-VM -SnapshotName "InitialConfig" 
