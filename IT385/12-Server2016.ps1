#######################################################################
#
# Run on Server2016 once OS is installed
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

$session2016 = New-PSSession -VMName Server2016 -Credential $cred

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Rename-HostedVM $session2016 "Server2016"
#endregion

#region Configure OS
# Setup session (must be done after rebooting)
$session2016 = New-PSSession -VMName Server2016 -Credential $cred

# Rename NICs 
Invoke-Command -Session $session2016 -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }


# Set UP addresses 
Set-HostedIP $session2016 "Internal" "192.168.0.101" 24 "192.168.0.250" "8.8.8.8"

# Configure Power save 
Set-HostedPowerSave $session2016

# IE Enhaced mode 
Invoke-Command -Session $session2016 -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 
    }

# Set UAC 
Set-HostedUAC $session2016

# Copy BGInfo
Copy-Item -ToSession $session2016 -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
 # Set autorun
Invoke-Command -Session $session2016 -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
    }
    
# Set password expiration
Set-HostedPassword $session2016
#endregion


Invoke-Command -VMName Server2016 -Credential $cred -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:CB7KF-BWN84-R7R2Y-793K2-8XDDG
    }
Invoke-Command -VMName Server2016 -Credential $cred -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk TMJ3Y-NTRTM-FJYXT-T22BY-CWG3J
    }