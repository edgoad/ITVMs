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
$isoPath = "c:\VMs\W2k2016.ISO"
$classVMs = "ServerDC1", "ServerDM1", "ServerSA1"

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# delete template VM, but leave HDD
Remove-VM "Svr2016Template" -Force

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch  -Generation 2
    Add-VMDvdDrive -VMName $vmName -Path c:\VMs\W2k2016.ISO
}

# Add DM2 into array to be included in remaining tasks
$classVMs += "ServerDM2"

#Create additional HD
foreach($vmName in $classVMs){
    New-VHD -Path $("$vmPath\$vmName" + "_01.vhdx") -SizeBytes 20GB
    New-VHD -Path $("$vmPath\$vmName" + "_02.vhdx") -SizeBytes 15GB
    New-VHD -Path $("$vmPath\$vmName" + "_03.vhdx") -SizeBytes 10GB
    Add-VMHardDiskDrive -VMName $vmName -Path $("$vmPath\$vmName" + "_01.vhdx")
    Add-VMHardDiskDrive -VMName $vmName -Path $("$vmPath\$vmName" + "_02.vhdx")
    Add-VMHardDiskDrive -VMName $vmName -Path $("$vmPath\$vmName" + "_03.vhdx")
}

#Mount ISO
foreach($vmName in $classVMs){
    Set-VMDvdDrive -VMName $vmName -Path $isoPath
}
# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Get-VM | Set-VMProcessor -Count 2

#######################################################################
#
# Power on Each VM and configure
# When finished, run the remaining scripts
#
#######################################################################
