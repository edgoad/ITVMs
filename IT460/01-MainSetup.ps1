#######################################################################
#
# First script for building Hyper-V environment for IT 460
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Dowload and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
(new-object System.Net.WebClient).DownloadFile($url, $output)
Import-Module $output
Remove-Item $output

# Disable Server Manager at startup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Setup first interface
if ( $(Get-NetAdapter | Measure-Object).Count -eq 1 ){
    Write-Host "Setting Public adapter name"
    Get-NetAdapter | Rename-NetAdapter -NewName Public
}
else{
    Write-Host "Cannot set Public interface name. Confirm interfaces manually."
}
# Install Hyper-V
Install-HypervAndTools

# Create virtual swith
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal')){
    Write-Host "Creating Internal vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal
} else { Write-Host "Internal vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'Internal')){
    Write-Host "Configuring Internal adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
    New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24
} else { Write-Host "Internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24

#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
Install-7Zip

#Install starwind converter
Install-Starwind

# Configure logout after 10 minutes
Set-Autologout

#######################################################################
# Start setting up Hyper-V
#######################################################################
Set-HypervDefaults

##############################################################################
# Download ISO files for installation
##############################################################################
# Download Kali ISO
# Review URL for latest version
Write-Host "Downloading Kali (this may take some time)"
$url = "https://cdimage.kali.org/kali-2020.2/kali-linux-2020.2-installer-amd64.iso"
$output = "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download DVWA
Write-Host "Downloading DVWA (this may take some time)"
$url = "http://www.dvwa.co.uk/DVWA-1.0.7.iso"
$output = "c:\VMs\DVWA-1.0.7.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Windows Server 2008 R2
Write-Host "Downloading Windows Server 2008 R2 (this may take some time)"
# https://archive.org/download/windowsserver2008r2x64/Windows%20Server%202008%20R2%20x64.iso
# https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso
$url = "https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso"
$output = "c:\VMs\windowsserver2008r2x64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Ubuntu 20.04
Write-Host "Downloading Ubuntu 20.04 (this may take some time)"
$url = "http://releases.ubuntu.com/20.04//ubuntu-20.04.1-live-server-amd64.iso"
$output = "c:\VMs\ubuntu-20.04.1-live-server-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Metasploitable 2
Write-Host "Downloading Metasploitable (this may take some time)"
$url = "http://downloads.metasploit.com/data/metasploitable/metasploitable-linux-2.0.0.zip"
$output = "$env:TEMP\metasploitable-linux-2.0.0.zip"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

#Download Windows 10 ISO
Write-Host "Downloading Windows 10 (this may take some time)"
$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$output = "c:\VMs\Windows10.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
if ( ! (Get-VM | Where-Object Name -EQ "Kali Linux")){
    Write-Host "Creating VM: Kali Linux"
	new-VM -Name "Kali Linux" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\KaliLinux.vhdx" -NewVHDSizeBytes 100GB -SwitchName Private
	Add-VMNetworkAdapter -VMName "Kali Linux" -SwitchName Internal
}
if ( ! (Get-VM | Where-Object Name -EQ "DVWA")){
    Write-Host "Creating VM: DVWA"
    new-VM -Name "DVWA" -MemoryStartupBytes 1GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DVWA.vhdx" -NewVHDSizeBytes 20GB -SwitchName Private
}

#Mount ISO
Set-VMDvdDrive -VMName "Kali Linux" -Path "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
Set-VMDvdDrive -VMName "DVWA" -Path "c:\VMs\ubuntu-20.04.1-live-server-amd64.iso"

##############################################################################
# Setup Metasploitable
##############################################################################
# Extract, convert, and import Metasploitable2
	# Extract
$msVersion = "metasploitable-linux-2.0.0"
Write-Host "Extracting $msVersion ZIP file"
$metasploitableZipFile = "$env:TEMP\$msVersion.zip"
$metasploitableHardDiskFilePath = "c:\VMs\Virtual Hard Disks\$msVersion.vhdx"
$swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
#Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
Start-Process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x $metasploitableZipFile -o$env:TEMP\$msVersion\" -Wait

# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\$msVersion\*.vmdk" -Recurse | Select-Object -expand FullName
# run twice, because the first time doesnt seem to work
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait

	# Import Metasploitable
Write-Host "Importing $msVersion"
new-vm -Name $msVersion -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 512MB
	# configure NIC
get-vm -Name $msVersion | Add-VMNetworkAdapter -SwitchName "Private" -IsLegacy $true
# Set all adapters to private
get-vm -Name $msVersion | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "Private"
# Delete %TEMP% files
Remove-Item $metasploitableZipFile -Force
Remove-Item "$env:TEMP\$msVersion" -Force -Recurse

$msVersion = "metasploitable3-ub1404"
Write-Host "Extracting $msVersion"
$metasploitableZipFile = "$env:TEMP\$msVersion.ova"
$metasploitableHardDiskFilePath = "c:\VMs\Virtual Hard Disks\$msVersion.vhdx"
$swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
#Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
#& 'C:\Program Files\7-Zip\7z.exe' x .\Metasploitable3-ub1404.ovf -oMetasploitable3-ub1404\
Start-Process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x $metasploitableZipFile -o$env:TEMP\$msVersion\" -Wait

	# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\$msVersion\*.vmdk" -Recurse | Select-Object -expand FullName
# run twice, because the first time doesnt seem to work
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait

	# Import Metasploitable
Write-Host "Importing $msVersion"
new-vm -Name $msVersion -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 512MB
		# configure NIC
#get-vm -Name $msVersion | Add-VMNetworkAdapter -SwitchName "Private" -IsLegacy $true
# Set all adapters to private
get-vm -Name $msVersion | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "Private"

# Delete %TEMP% files
Remove-Item $metasploitableZipFile -Force
Remove-Item "$env:TEMP\$msVersion" -Force -Recurse


$msVersion = "metasploitable3-win2k8"
Write-Host "Extracting $msVersion ZIP file"
$metasploitableZipFile = "$env:TEMP\$msVersion.ova"
$metasploitableHardDiskFilePath = "c:\VMs\Virtual Hard Disks\$msVersion.vhdx"
$swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
#Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
#& 'C:\Program Files\7-Zip\7z.exe' x $metasploitableZipFile -o"$env:TEMP\$msVersion\"
Start-Process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x $metasploitableZipFile -o$env:TEMP\$msVersion\" -Wait

	# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\$msVersion\*.vmdk" -Recurse | Select-Object -expand FullName
# run twice, because the first time doesnt seem to work
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait

	# Import Metasploitable
Write-Host "Importing $msVersion"
new-vm -Name $msVersion -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 2048MB
	# configure NIC
#get-vm -Name $msVersion | Add-VMNetworkAdapter -SwitchName "Private" -IsLegacy $true
# Set all adapters to private
get-vm -Name $msVersion | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "Private"

# Delete %TEMP% files
Remove-Item $metasploitableZipFile -Force
Remove-Item "$env:TEMP\$msVersion" -Force -Recurse


##############################################################################
# Configure VMs
##############################################################################
# Setup memory
#Get-VM | Set-VMMemory -DynamicMemoryEnabled $true

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# setup bginfo
Set-DesktopDefaults

# Clean up temp files
# Clear-TempFiles

# Download logon information
Write-Host "Downloading Logon Information"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/Logon%20Information.txt"
$output = "c:\Users\Public\Desktop\Logon Information.txt"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Network Diagram
Write-Host "Downloading Network Diagram"
$url = "https://github.com/edgoad/ITVMs/raw/master/IT460/IT460.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output




#########################
# configuration notes
# metasploitable2 static IP instructions: https://www.howtoforge.com/community/threads/setting-static-ip-on-ubuntu-8-04-server.25277/
# Kali needs both Private and Internal networks, you may need to add the connection
# Metasploitable3 instructions at https://github.com/rapid7/metasploitable3/#to-build-automatically
