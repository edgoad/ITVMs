#######################################################################
#
# Last script for building Hyper-V environment for IT 160
# Shuts down all VMs and takes snapshots
#
#######################################################################

Get-VM | Stop-VM 
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot" 
