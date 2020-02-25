# Rename NICs 
Rename-NetAdapter -Name Ethernet -NewName Internal 
Rename-NetAdapter -Name "Ethernet 2" -NewName Private 

# Set UP addresses 
New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.4 -PrefixLength 24 -DefaultGateway 192.168.0.250 
New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.4 -PrefixLength 24 
Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 192.168.0.1

# Configure Power save 
powercfg -change -monitor-timeout-ac 0 

# IE Enhaced mode 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 

# Set UAC 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 

# Configure name 
Rename-Computer -NewName ServerSA1 -force -restart 

