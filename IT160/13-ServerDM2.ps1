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
Set-HostedIP $sessionDM2 "Internal" "192.168.0.3" 24 "192.168.0.250" "192.168.0.1"

# Configure Power save 
Set-HostedPowerSave $sessionDM2

# Set UAC 
Set-HostedUAC $sessionDM2

# Set password expiration

Set-HostedPassword $sessionDM2
#endregion

#region Join Domain
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################

Add-HostedtoDomain $sessionDM2
#endregion
