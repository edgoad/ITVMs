#######################################################################
#
# Run on ServerDC1 after additional NICs are setup
#
#######################################################################

# Rename NICs 
Rename-NetAdapter -Name "Ethernet 2" -NewName Private 

# Set UP addresses 
New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.1 -PrefixLength 24 


# Note: These lines are duplicate, but could be beneficial to re-run
# Configure Power save 
powercfg -change -monitor-timeout-ac 0 

# IE Enhaced mode 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 

# Set UAC 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
