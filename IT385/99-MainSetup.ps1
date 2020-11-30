#######################################################################
#
# Last script for building Hyper-V environment for IT 385
# Shuts down all VMs and takes snapshots
#
#######################################################################

Get-VM | Stop-VM 
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot" 
