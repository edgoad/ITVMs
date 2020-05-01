#######################################################################
#
# Run on Win10VM once OS is installed
# Updated to run remotely using Hyper-v Direct
# NOTE: Will require several reboots
#
#######################################################################


#region Configure OS
# Setup session (must be done after rebooting)
$sessionWin10 = New-PSSession -VMName Win10VM -Credential $cred

# Rename NICs 
Invoke-Command -Session $sessionWin10 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
Invoke-Command -Session $sessionWin10 -ScriptBlock { 
    New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.4 -PrefixLength 24 -DefaultGateway 192.168.0.250 
    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 192.168.0.1
    }

# Configure Power save 
Invoke-Command -Session $sessionWin10 -ScriptBlock { 
    powercfg -change -monitor-timeout-ac 0 
    }


# Copy BGInfo
Copy-Item -ToSession $sessionWin10 -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
 # Set autorun
Invoke-Command -Session $sessionWin10 -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
    }
#endregion

#region Rename server
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName Win10VM -Credential $cred -ScriptBlock { 
    Rename-Computer -NewName Win10VM -force -restart 
    }
#endregion
