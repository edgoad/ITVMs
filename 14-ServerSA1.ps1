#######################################################################
#
# Run on ServerSA1 once OS is installed
# Updated to run remotely using Hyper-v Direct
# NOTE: Will require several reboots
#
#######################################################################

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName ServerSA1 -Credential $cred -ScriptBlock { 
    Rename-Computer -NewName ServerSA1 -force -restart 
    }

# Setup session (must be done after rebooting)
$sessionSA1 = New-PSSession -VMName ServerSA1 -Credential $credDom

# Rename NICs 
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.2 -PrefixLength 24 -DefaultGateway 192.168.0.250 
    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 192.168.0.1
    }

# Configure Power save 
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    powercfg -change -monitor-timeout-ac 0 
    }

# IE Enhaced mode 
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 
    }

# Set UAC 
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
    }

# Copy BGInfo
Copy-Item -ToSession $sessionSA1 -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
 # Set autorun
Invoke-Command -Session $sessionSA1 -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
    }

