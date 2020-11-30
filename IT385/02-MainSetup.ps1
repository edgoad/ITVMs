#######################################################################
#
# Second script for building Hyper-V environment for IT 385
# Builds VMs after the template has been create
#
#######################################################################

$templatePath = "c:\VMs\FedoraTemplate.vhdx"
$vmPath = "C:\VMs"
$vhdPath = "C:\VMs"
$vmSwitch = "Internal"
$isoPath = "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
$classVMs = "Ansible", "Web1", "Web2", "DB1", "DB2"

# Send message to complete Template first
write-host "Ensure FedoraTemplate VM is installed and sysprepped before continuing"

# delete template VM, but leave HDD
Remove-VM "FedoraTemplate" -Force

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
}



$templatePath = "c:\VMs\CSRTemplate.vhdx"
$vmPath = "C:\VMs"
$vhdPath = "C:\VMs"
$vmSwitch = "Internal"
$isoPath = "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
$classVMs = "CSR1", "CSR2"

# Send message to complete Template first
write-host "Ensure CSRTemplate VM is installed and sysprepped before continuing"

# delete template VM, but leave HDD
Remove-VM "CSRTemplate" -Force

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch
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
