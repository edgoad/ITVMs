#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Builds VMs after the template has been create
#
#######################################################################

$templatePath = "c:\VMs\Svr2016Template.vhdx"
$vmPath = "C:\VMs"
$vhdPath = "C:\VMs"
$vmSwitch = "Internal"
$isoPath = "c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$classVMs = "ServerDC1", "ServerDM1", "ServerDM2", "ServerSA1"

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

# delete template VM, but leave HDD
Remove-VM "Svr2016Template" -Force

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
}



#Create additional HD
foreach($vmName in $classVMs){
    New-VHD -Path $vmPath\$vmName_01.vhdx -SizeBytes 20GB
    New-VHD -Path $vmPath\$vmName_02.vhdx -SizeBytes 15GB
    New-VHD -Path $vmPath\$vmName_03.vhdx -SizeBytes 10GB
    Add-VMHardDiskDrive -VMName $vmName -Path $vmPath\$vmName_01.vhdx
    Add-VMHardDiskDrive -VMName $vmName -Path $vmPath\$vmName_02.vhdx
    Add-VMHardDiskDrive -VMName $vmName -Path $vmPath\$vmName_03.vhdx
}

#Mount ISO
foreach($vmName in $classVMs){
    Set-VMDvdDrive -VMName $vmName -Path $isoPath
}
# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown



#######################################################################
#
# Power on Each VM and configure
# When finished, run the remaining scripts
#
#######################################################################
