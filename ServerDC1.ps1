# Configure name 
Rename-Computer -NewName ServerDC1 -force -restart 

# Rename NICs 
Rename-NetAdapter -Name Ethernet0 -NewName Internal 
Rename-NetAdapter -Name Ethernet1 -NewName Private 

# Set UP addresses 
New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.1 -PrefixLength 24 -DefaultGateway 192.168.0.250 
New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.1 -PrefixLength 24 
Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 127.0.0.1 

# Install ADDS 
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools 

# Configure AD 
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

 
