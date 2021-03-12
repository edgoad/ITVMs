#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Builds VMs after the template has been create
#
#######################################################################

$templatePath = "C:\VMs\Virtual Hard Disks\Svr2016Template.vhdx"
$vmPath = "C:\VMs"
$vhdPath = "C:\VMs\Virtual Hard Disks"
$vmSwitch = "Private"
$isoPath = "c:\VMs\W2k2016.ISO"
$classVMs = "Web", "DNS", "DC", "DM"

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# delete template VM, but leave HDD
Remove-VM "Svr2016Template" -Force

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vhdPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch  -Generation 2
    Add-VMDvdDrive -VMName $vmName -Path c:\VMs\W2k2016.ISO
}

# Move VMs to right switch
Get-VMNetworkAdapter -VMName "web", "DNS" | Connect-VMNetworkAdapter -SwitchName "DMZ"


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
