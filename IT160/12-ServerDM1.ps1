#######################################################################
#
# Run on ServerDM1 once OS is installed
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

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName ServerDM1 -Credential $cred -ScriptBlock { 
    Rename-Computer -NewName ServerDM1 -force -restart 
    }
#endregion

#region Configure OS
# Setup session (must be done after rebooting)
$sessionDM1 = New-PSSession -VMName ServerDM1 -Credential $cred

# Rename NICs 
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    New-NetIPAddress -InterfaceAlias Internal -IPAddress 10.99.0.201 -PrefixLength 24 -DefaultGateway 10.99.0.250 
    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 10.99.0.220
    }

# Configure Power save 
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    powercfg -change -monitor-timeout-ac 0 
    }

# IE Enhaced mode 
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 
    }

# Set UAC 
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
    }

# Copy BGInfo
Copy-Item -ToSession $sessionDM1 -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
 # Set autorun
Invoke-Command -Session $sessionDM1 -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
    }

# Set password expiration
Invoke-Command -Session $sessionDM1 -ScriptBlock {
    Get-LocalUser | Where-Object Enabled -EQ True | Set-LocalUser -PasswordNeverExpires $true
    }

#endregion

#region Join domain
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -Session $sessionDM1 -ScriptBlock { 
    $user = "AZ800\administrator"
    $pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
    add-computer -domainname AZ800.corp -Credential $cred -restart -force
    }
#endregion
