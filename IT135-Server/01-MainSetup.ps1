#######################################################################
#
# First script for building Hyper-V environment for IT 135
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
# Likely will need to update download URL
New-Item -ItemType Directory -Path c:\VMs -Force
#$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
#$url = "https://software-download.microsoft.com/pr/Win10_1909_English_x64.iso?t=4385b35e-5f09-429b-b404-fc405e6d403c&e=1588434711&h=a8be8c67e4aef0a73125b0169ca73936"
#$url = "https://software-download.microsoft.com/pr/Win10_1909_English_x64.iso"
$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"

$output = "c:\VMs\18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$start_time = Get-Date

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"
Set-VMHost -EnableEnhancedSessionMode:$true

#Create VMs
new-VM -Name Win10VM -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Win10VM.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal

# Setup memory
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true

#Create additional HD
#New-VHD -Path C:\VMs\Win10VM_01.vhdx -SizeBytes 20GB
#New-VHD -Path C:\VMs\Win10VM_02.vhdx -SizeBytes 15GB
#New-VHD -Path C:\VMs\Win10VM_03.vhdx -SizeBytes 10GB
#Add-VMHardDiskDrive -VMName Win10VM -Path C:\VMs\Win10VM_01.vhdx
#Add-VMHardDiskDrive -VMName Win10VM -Path C:\VMs\Win10VM_02.vhdx
#Add-VMHardDiskDrive -VMName Win10VM -Path C:\VMs\Win10VM_03.vhdx

#Mount ISO
Set-VMDvdDrive -VMName Win10VM -Path c:\VMs\18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso


############################################
# Set RDP idle logout (via local policy)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value 600000 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value 600000 -Type "Dword"

############################################
# Setup idle-logoff (https://github.com/lithnet/idle-logoff/)
$LocalTempDir = $env:TEMP
$InstallFile = "lithnet.idlelogoff.setup.msi"
$url = "https://github.com/lithnet/idle-logoff/releases/download/v1.1.6999/lithnet.idlelogoff.setup.msi"
$output = "$LocalTempDir\$InstallFile"

(new-object System.Net.WebClient).DownloadFile($url, $output)
Start-Process $output -ArgumentList "/qn" -Wait

# Configure idle-logoff timeout
New-Item -Path "HKLM:\SOFTWARE\Lithnet"
New-Item -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Action" -Value 2 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Enabled" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IdleLimit" -Value 10 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IgnoreDisplayRequested" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningEnabled" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningMessage" -Value "Your session has been idle for too long, and you will be logged out in {0} seconds" -Type "String"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningPeriod" -Value 60 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Lithnet.idlelogoff -Value '"C:\Program Files (x86)\Lithnet\IdleLogoff\Lithnet.IdleLogoff.exe" /start'

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
