#######################################################################
#
# Run on ServerDM2 once OS is installed
# Updated to run remotely using Hyper-v Direct
# NOTE: Will require several reboots
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Download and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
if (-not(Test-Path -Path $output -PathType Leaf)) {
    (new-object System.Net.WebClient).DownloadFile($url, $output)
}
Import-Module $output

#region Rename server
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

$sessionDM2 = New-PSSession -VMName ServerDM2 -Credential $cred

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
#Invoke-Command -VMName ServerDM2 -Credential $cred -ScriptBlock { 
#    Rename-Computer -NewName ServerDM2 -force -restart 
#    }
Rename-HostedVM $sessionDM2 "ServerDM2"
#endregion

#region Configure OS
# Setup session (must be done after rebooting)
$sessionDM2 = New-PSSession -VMName ServerDM2 -Credential $cred

# Rename NICs 
Invoke-Command -Session $sessionDM2 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
#Invoke-Command -Session $sessionDM2 -ScriptBlock { 
#    New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.3 -PrefixLength 24 -DefaultGateway 192.168.0.250 
#    }
# Set UP addresses 
#Invoke-Command -Session $sessionDM2 -ScriptBlock { 
#    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 192.168.0.1
#    }
Set-HostedIP $sessionDM2 "Internal" "192.168.0.3" 24 "192.168.0.250" "192.168.0.1"

# Configure Power save 
#Invoke-Command -Session $sessionDM2 -ScriptBlock { 
#    powercfg -change -monitor-timeout-ac 0 
#    }
Set-HostedPowerSave $sessionDM2

# Set UAC 
#Invoke-Command -Session $sessionDM2 -ScriptBlock { 
#    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
#    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
#    }
Set-HostedUAC $sessionDM2

# No BGInfo - server core
## Copy BGInfo
#Copy-Item -ToSession $sessionDM2 -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
# # Set autorun
#Invoke-Command -Session $sessionDM2 -ScriptBlock {
#    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
#    }

    # Set password expiration
#Invoke-Command -Session $sessionDM2 -ScriptBlock {
#    Get-LocalUser | Where-Object Enabled -EQ True | Set-LocalUser -PasswordNeverExpires $true
#    }
Set-HostedPassword $sessionDM2
#endregion

#region Join Domain
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################
#Invoke-Command -Session $sessionDM2 -ScriptBlock { 
#    $user = "mcsa2016\administrator"
#    $pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
#    $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
#    add-computer -domainname mcsa2016.local -Credential $cred -restart -force
#    }
Add-HostedtoDomain $sessionDM2
#endregion
