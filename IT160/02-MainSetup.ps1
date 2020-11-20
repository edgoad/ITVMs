#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Builds VMs after the template has been create
#
#######################################################################

$templatePath = "c:\VMs\Srv2016Template.vhdx"
$vmPath = "C:\VMs"
$vhdPath = "C:\VMs"
$vmSwitch = "Internal"
$isoPath = "c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

# delete template VM, but leave HDD
Remove-VM "Svr2016Template" -Force

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# Create differencing disks for VMs
$vmName = "ServerDC1"
$VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
$vmName = "ServerDM1"
$VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
$vmName = "ServerDM2"
$VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
$vmName = "ServerSA1"
$VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch


#Create additional HD
New-VHD -Path $vmPath\ServerDM1_01.vhdx -SizeBytes 20GB
New-VHD -Path $vmPath\ServerDM1_02.vhdx -SizeBytes 15GB
New-VHD -Path $vmPath\ServerDM1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM1 -Path $vmPath\ServerDM1_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path $vmPath\ServerDM1_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path $vmPath\ServerDM1_03.vhdx
New-VHD -Path $vmPath\ServerDM2_01.vhdx -SizeBytes 20GB
New-VHD -Path $vmPath\ServerDM2_02.vhdx -SizeBytes 15GB
New-VHD -Path $vmPath\ServerDM2_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM2 -Path $vmPath\ServerDM2_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path $vmPath\ServerDM2_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path $vmPath\ServerDM2_03.vhdx
New-VHD -Path $vmPath\ServerSA1_01.vhdx -SizeBytes 20GB
New-VHD -Path $vmPath\ServerSA1_02.vhdx -SizeBytes 15GB
New-VHD -Path $vmPath\ServerSA1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerSA1 -Path $vmPath\ServerSA1_01.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path $vmPath\ServerSA1_02.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path $vmPath\ServerSA1_03.vhdx

#Mount ISO
Set-VMDvdDrive -VMName ServerDC1 -Path $isoPath
Set-VMDvdDrive -VMName ServerDM1 -Path $isoPath
Set-VMDvdDrive -VMName ServerDM2 -Path $isoPath
Set-VMDvdDrive -VMName ServerSA1 -Path $isoPath

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
