#######################################################################
#
# Run on ServerDM1 once OS is installed
# NOTE: Will require several reboots
#
#######################################################################

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Rename-Computer -NewName ServerDC1 -force -restart 

# Rename NICs 
Rename-NetAdapter -Name Ethernet0 -NewName Internal 

# Set UP addresses 
New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.1 -PrefixLength 24 -DefaultGateway 192.168.0.250 
Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 127.0.0.1 

# Install ADDS 
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools 

# Configure AD 
#######################################################################
# NOTE: REBOOT!
#######################################################################
$smPass = ConvertTo-SecureString "Password01" -AsPlainText -Force 
Install-ADDSForest -DomainName "MCSA2016.local" -SafeModeAdministratorPassword $smPass -Confirm:$false 


# Fix DNS (if needed) 
Get-DnsServerForwarder | Remove-DnsServerForwarder -Force 

# Configure Power save 
powercfg -change -monitor-timeout-ac 0 

# IE Enhaced mode 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 

# Set UAC 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 

 
