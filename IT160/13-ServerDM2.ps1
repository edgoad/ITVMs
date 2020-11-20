#######################################################################
#
# Run on ServerDM2 once OS is installed
# Updated to run remotely using Hyper-v Direct
# NOTE: Will require several reboots
#
#######################################################################

#region Rename server
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName ServerDM2 -Credential $cred -ScriptBlock { 
    Rename-Computer -NewName ServerDM2 -force -restart 
    }
#endregion

#region Configure OS
# Setup session (must be done after rebooting)
$sessionDM2 = New-PSSession -VMName ServerDM2 -Credential $cred

# Rename NICs 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.3 -PrefixLength 24 -DefaultGateway 192.168.0.250 
    }
# Set UP addresses 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 192.168.0.1
    }

# Configure Power save 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    powercfg -change -monitor-timeout-ac 0 
    }


# Set UAC 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
    }
#endregion

#region Join Domain
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    $user = "mcsa2016\administrator"
    $pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
    add-computer -domainname mcsa2016.local -Credential $cred -restart -force
    }
#endregion
