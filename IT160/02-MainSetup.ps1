#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Builds VMs after the template has been create
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Dowload and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
(new-object System.Net.WebClient).DownloadFile($url, $output)
Import-Module $output
#Remove-Item $output


$templatePath = "c:\BaseVMs\Svr2022Template.vhdx"
$vmPath = "c:\BaseVMs"
$vhdPath = "c:\BaseVMs"
$vmSwitch = "Internal"
$isoPath = "c:\ISOs\W2k22.ISO"
$classVMs = "ServerDC1", "ServerDM1", "ServerSA1"

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# Disable Windows Update
$vmSession = New-PSSession Svr2022Template  -Credential $cred
Disable-WindowsUpdatesVM($vmSession)
$vmSession2 = New-PSSession ServerDM2  -Credential $cred
Disable-WindowsUpdatesVM($vmSession2)

#initiate sysprep
Invoke-Command -VMName Svr2022Template -Credential $cred -ScriptBlock { 
    & 'c:\windows\system32\sysprep\sysprep.exe' /generalize /shutdown /oobe
}

# Send message to complete Template first
write-host "Ensure Template VM is installed and sysprepped before continuing"

# Compress/optimize vhd size
Optimize-VHD $templatePath -Mode Full

# Set Template HDD permissions to read-only
Set-ItemProperty -Path $templatePath -Name IsReadOnly -Value $true

# delete template VM, but leave HDD
Remove-VM "Svr2022Template" -Force

# Create differencing disks for VMs
# Based on https://matthewfugel.wordpress.com/2017/02/18/hyper-v-quick-deploy-vms-with-powershell-differencing-disk/
foreach($vmName in $classVMs){
    $VHD = New-VHD -Path ($vmPath + "\" + $vmname + ".vhdx") -ParentPath $templatePath -Differencing
    new-VM -Name $vmName -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath $VHD.Path -SwitchName $vmSwitch  -Generation 2
    Add-VMDvdDrive -VMName $vmName -Path c:\ISOs\W2k22.ISO
}


# Add DM2 into array to be included in remaining tasks
$classVMs += "ServerDM2"

#Create additional HD for DM1
$extraDiskVMs = "ServerDM1", "ServerSA1"
foreach($vmName in $extraDiskVMs){
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
# Set dynamic memory for all VMs
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 4GB -StartupBytes 4GB -MaximumBytes 6GB

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Get-VM | Set-VMProcessor -Count 4

#######################################################################
#
# Power on Each VM and configure
# When finished, run the remaining scripts
#
#######################################################################
