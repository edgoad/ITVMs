##############################################
# Power on all Windows Vms and configure administrator accounts
##############################################



# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)


Invoke-Command -VMName "Web", "DNS", "DC", "DM"  -Credential $cred -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:CB7KF-BWN84-R7R2Y-793K2-8XDDG
    }
# wait for reboot
Invoke-Command -VMName "Web", "DNS", "DC", "DM" -Credential $cred -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk TMJ3Y-NTRTM-FJYXT-T22BY-CWG3J
    }

# Shutdown and snapshot
get-vm "Web", "DNS", "DC", "DM" | Stop-VM
get-vm "Web", "DNS", "DC", "DM" | Checkpoint-VM -SnapshotName "Initial snapshot" 


# rename host on first boot
$command = 'powershell -Command "& { rename-computer -newname $( $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
