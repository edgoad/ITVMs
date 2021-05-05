#######################################################################
#
# Second script for building Hyper-V environment for IT 340
# Builds VMs after the template has been create
#
#######################################################################
# Change directory to %TEMP% for working
cd $env:TEMP

# Download and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
if (-not(Test-Path -Path $output -PathType Leaf)) {
    (new-object System.Net.WebClient).DownloadFile($url, $output)
}
Import-Module $output

$vmPath = "C:\VMs"
$vhdPath = "$vmPath\Virtual Hard Disks"
$templatePath = "$vhdPath\Svr2016Template.vhdx"
$vmSwitch = "Private"
$isoPath = "c:\VMs\W2k2016.ISO"
$classVMs = "Web", "DNS", "DC", "DM"

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

if ((Get-VMSwitch | Where-Object -Property Name -EQ "Private").count -eq 0)
{
    write-host "Creating Private VMswitch"
    New-VMSwitch -SwitchType Private -Name Private
}if ((Get-VMSwitch | Where-Object -Property Name -EQ "DMZ").count -eq 0)
{
    write-host "Creating DMZ VMswitch"
    New-VMSwitch -SwitchType Private -Name DMZ
}

# Configure Palo Alto NICs
Add-VMNetworkAdapter -VMName "PaloAlto" -SwitchName WAN
Add-VMNetworkAdapter -VMName "PaloAlto" -SwitchName Private
Add-VMNetworkAdapter -VMName "PaloAlto" -SwitchName DMZ


# Set Template HDD permissions to read-only
#Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

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
Get-VMNetworkAdapter -VMName "Web", "DNS" | Connect-VMNetworkAdapter -SwitchName "DMZ"


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
# Power on Each VM and configure if needed
#
#######################################################################
