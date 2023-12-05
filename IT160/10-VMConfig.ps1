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

$classVMs = "ServerDC1", "ServerDM1", "ServerSA1", "ServerDM2"
$VMIPs = @{"ServerDC1" = "10.99.0.220"; "ServerDM1" = "10.99.0.201"; "ServerSA1" = "10.99.0.203"; "ServerDM2" = "10.99.0.202"}
$VMSessions = @{"ServerDC1" = New-PSSession -VMName ServerDC1 -Credential $cred; 
    "ServerDM1" = New-PSSession -VMName ServerDM1 -Credential $cred; 
    "ServerSA1" = New-PSSession -VMName ServerSA1 -Credential $cred; 
    "ServerDM2" = New-PSSession -VMName ServerDM2 -Credential $cred}

#region Rename server


# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #     Rename-Computer -NewName $vmName -force -restart 
    # }
    Rename-HostedVM $VMSessions[$vmName] $vmName
}
#endregion

#region Configure OS
# Setup session (must be done after rebooting)
foreach($vmName in $classVMs){
    $VMSessions[$vmName] = New-PSSession -VMName $vmName -Credential $cred
}

# Rename NICs to Eth0
foreach($vmName in $classVMs){
    Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
        Get-NetAdapter | Rename-NetAdapter -NewName Ethernet0 
    }
}

# Set UP addresses 
foreach($vmName in $classVMs){
    # Invoke-Command -Session $VMSessions[$vmName] -ScriptBlock { 
    #     New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress $VMIPs[$vmname] -PrefixLength 24 -DefaultGateway 10.99.0.250 
    #     Set-DnsClientServerAddress -InterfaceAlias Ethernet0 -ServerAddresses 10.99.0.220
    # }
    Set-HostedIP $VMSessions[$vmName] "Ethernet0" $VMIPs[$vmname] 24 "10.99.0.250" "10.99.0.220"

}
#endregion

#region Setup AD
# Install ADDS 
Invoke-Command -Session $VMSessions["ServerDC1"] -ScriptBlock {
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools 
} 
Invoke-Command -Session $VMSessions["ServerDC1"] -ScriptBlock {
    $smPass = ConvertTo-SecureString "Password01" -AsPlainText -Force 
    Install-ADDSForest -DomainName "AZ800.corp" -SafeModeAdministratorPassword $smPass -Confirm:$false 
}
#endregion
#######################################################################
# NOTE: REBOOT!
# Wait for DC1 to power on
#######################################################################
# Update credentials for AD domain
$userDom = "AZ800\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $passDom)
$VMSessions["ServerDC1"] = New-PSSession -VMName ServerDC1 -Credential $credDom


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
#endregion
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -Session $sessionSA1 -ScriptBlock { 
    add-computer -workgroupname AZ800 -restart -force
}
# Join domain
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -Session $VMSessions["ServerDM1"], $VMSessions["ServerDM2"] -ScriptBlock { 
    add-computer -domainname AZ800.corp -Credential $credDom -restart -force
}

