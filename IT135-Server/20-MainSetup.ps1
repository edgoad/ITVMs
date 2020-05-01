#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Run only after the OS is installed and initial configuration complete
#
#######################################################################

# Start VMs
Get-VM | Start-VM

# Setup credentials
$user = "Student"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)



# Change from Eval mode
Invoke-Command -VMName Win10VM -Credential $cred -ScriptBlock { 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name EditionID -Value "Enterprise"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CompositionEditionID -Value "Enterprise"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName -Value "Windows 10 Enterprise"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" -Name EditionID -Value "Enterprise"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" -Name CompositionEditionID -Value "Enterprise"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" -Name ProductName -Value "Windows 10 Enterprise"
    }

#region Use SLMGR to setup AVMA license key
# Setup credentials
$user = "Student"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

Invoke-Command -VMName Win10VM -Credential $cred -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk NPPR9-FWDCX-D2C8J-H872K-2YT43
    }
#endregion
