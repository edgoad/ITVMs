#######################################################################
#
# First script for building Hyper-V environment for IT 160
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Disable Server Manager at startup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Setup first interface
Get-NetAdapter | Rename-NetAdapter -NewName Public

# Install Hyper-V
Install-WindowsFeature Hyper-V -IncludeManagementTools -Restart

#######################################################################
# automatic reboot here
#######################################################################

# Create virtual swith
New-VMSwitch -SwitchType Internal -Name Internal

# Setup second interface
Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24

# Add Hyper-V shortcut
$SourceFileLocation = "%windir%\System32\virtmgmt.msc"
$ShortcutLocation = "C:\Users\Student\Desktop\Hyper-V Manager.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
$Shortcut.TargetPath = $SourceFileLocation
$Shortcut.Save()

#Download Windows ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$start_time = Get-Date

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"
Set-VMHost -EnableEnhancedSessionMode:$true

#Create VMs
new-VM -Name ServerDC1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDC1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM2 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM2.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerSA1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerSA1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal

# Setup memory
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true

#Create additional HD
New-VHD -Path C:\VMs\ServerDM1_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerDM1_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerDM1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_03.vhdx
New-VHD -Path C:\VMs\ServerDM2_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerDM2_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerDM2_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_03.vhdx
New-VHD -Path C:\VMs\ServerSA1_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerSA1_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerSA1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_01.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_02.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_03.vhdx

#Mount ISO
Set-VMDvdDrive -VMName ServerDC1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerDM1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerDM2 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerSA1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO

# Set RDP idle logout (maybe???)
# The MaxIdleTime is in milliseconds; by default, this script sets MaxIdleTime to 1 minutes.
$maxIdleTime = 10 * 60 * 1000
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value $maxIdleTime -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value $maxIdleTime -Type "Dword" -Force
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value 600000 -Type "Dword"

# enable PING on firewall
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# setup bginfo
#Download bginfo
New-Item -ItemType Directory -Path c:\bginfo -Force
$url = "https://live.sysinternals.com/Bginfo.exe"
$output = "C:\bginfo\Bginfo.exe"

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output

#Download default.bgi
$url = "https://github.com/edgoad/ITVMs/raw/master/default.bgi"
$output = "C:\bginfo\default.bgi"

Start-BitsTransfer -Source $url -Destination $output
# Set autorun
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"

# install chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object    System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

#######################################################################
#
# Setup BGInfo, save as c:\bginfo\default.ino
# Power on each VM and install the OS
# When finished, run the second script
#
#######################################################################
