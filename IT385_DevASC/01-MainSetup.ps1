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

# setup bginfo
Set-DesktopDefaults

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
Write-Host "Downloading Logon Information"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/Logon%20Information.txt"
$output = "c:\Users\Public\Desktop\Logon Information.txt"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Network Diagram
# Write-Host "Downloading Network Diagram"
# $url = "https://github.com/edgoad/ITVMs/raw/master/IT385/IT385.png"
# $output = "c:\Users\Public\Desktop\Network Diagram.png"
# Get-WebFile -DownloadUrl $url -TargetFilePath $output



#######################################################################
#
# Power on Template VM and install the OS
# Use Sysprep to generalize
# When finished, run the second script
#
#######################################################################
