#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Run only after the OS is installed and initial configuration complete
#
#######################################################################

# Start VMs
Get-VM | Start-VM

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

#region Use DISM to change Server Edition
#######################################################################
# NOTE: REBOOT!
# Will also return an error code - this is expected
#######################################################################
Invoke-Command -VMName Win10VM -Credential $cred -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:W269N-WFGWX-YVC9B-4J6C9-T83GX
    }
#endregion

#region Use SLMGR to setup AVMA license key
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

Invoke-Command -VMName Win10VM -Credential $cred -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk TMJ3Y-NTRTM-FJYXT-T22BY-CWG3J
    }
#endregion
