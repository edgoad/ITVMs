#######################################################################
#
# Run on ServerSA1 once OS is installed
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

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
$userDom = "AZ800\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $passDom)

$classVMs = "ServerDC1", "ServerDM1", "ServerSA1", "ServerDM2", "ServerHyperV"
$VMIPs = @{"ServerDC1" = "10.99.0.220"; "ServerDM1" = "10.99.0.201"; "ServerSA1" = "10.99.0.203"; "ServerDM2" = "10.99.0.202"; "ServerHyperV" = "10.99.0.10"}
$VMSessions = @{"ServerDC1" = New-PSSession -VMName ServerDC1 -Credential $credDom; 
    "ServerDM1" = New-PSSession -VMName ServerDM1 -Credential $cred; 
    "ServerSA1" = New-PSSession -VMName ServerSA1 -Credential $cred; 
    "ServerDM2" = New-PSSession -VMName ServerDM2 -Credential $cred; 
    "ServerHyperV" = New-PSSession -VMName ServerHyperV -Credential $cred}

#region Rename server




# Configure Power save 
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #     powercfg -change -monitor-timeout-ac 0 
    # }
    Set-HostedPowerSave $VMSessions[$vmName]
}
# IE Enhaced mode 
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 
    # }
    Set-HostedIEMode $VMSessions[$vmName]
}
# Set UAC 
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
    #     Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
    # }
    Set-HostedUAC $VMSessions[$vmName]
}
# Copy BGInfo
foreach($vmName in $classVMs){
    #Copy-Item -ToSession $VMSessions[$vmName] -Path "C:\bginfo\" -Destination "C:\bginfo\" -Force -Recurse
    Set-HostedBGInfo $VMSessions[$vmName]
}
 # Set autorun
#  foreach($vmName in $classVMs){
#     Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
#         Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"
#     }
#  }  
# Set password expiration
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #     Get-LocalUser | Where-Object Enabled -EQ True | Set-LocalUser -PasswordNeverExpires $true
    # }
    Set-HostedPassword $VMSessions[$vmName]
}
# Set Firewall Exception
Set-NetFirewallRule FPS-ICMP4-ERQ-In -Enabled true # host
foreach($vmName in $classVMs){
    Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
        Set-NetFirewallRule FPS-ICMP4-ERQ-In -Enabled true
    }
}
#endregion
#######################################################################
# NOTE: REBOOT!
#######################################################################

Invoke-Command -Session $VMSessions["ServerSA1"] -ScriptBlock { 
    add-computer -workgroupname AZ800 -restart -force
}
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -Session $VMSessions["ServerDM1"], $VMSessions["ServerDM2"] -ScriptBlock { 
    $user = "AZ800\administrator"
    $pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
    add-computer -domainname AZ800.corp -Credential $cred -restart -force
}

