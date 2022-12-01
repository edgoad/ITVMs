#######################################################################
#
# First script for building Hyper-V environment for IT 385
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Dowload and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
(new-object System.Net.WebClient).DownloadFile($url, $output)
Import-Module $output
Remove-Item $output

# Disable Windows Updates
Disable-WindowsUpdates

# setup bginfo
Set-DesktopDefaults

# other defaults
Set-AdminNeverExpire
Add-DefenderExclusions
Start-NetFrameworkOptimization

#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
Install-7Zip

# Configure logout after 10 minutes
Set-Autologout


# Download devasc-sa.py
New-Item -Path "c:\Users\student\Desktop\LabFiles" -ItemType Directory
Write-Host "Downloading devasc-sa.py"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/devasc-sa.py"
$output = "c:\Users\student\Desktop\LabFiles\devasc-sa.py"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download logon information
#Write-Host "Downloading Logon Information"
#$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/Logon%20Information.txt"
#$output = "c:\Users\Public\Desktop\Logon Information.txt"
#Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Rename VM after reboot
Add-RenameAfterReboot
