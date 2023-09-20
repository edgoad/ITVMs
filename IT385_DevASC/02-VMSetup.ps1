#######################################################################
#
# Second script for building Hyper-V environment for IT 385
# Installs starwind converter and sets up VMs
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Dowload and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
(new-object System.Net.WebClient).DownloadFile($url, $output)
Import-Module $output
#Remove-Item $output


#Install starwind converter
Install-Starwind

##############################################################################
# Setup DEVASC VM
##############################################################################
# Extract, convert, and import Metasploitable2
# Extract
$vm_name = "DEVASC_VM"
write-host "Moving file to %TMP%"
Move-Item $HOME\Downloads\$vm_name.ova $env:TEMP
Write-Host "Extracting $vm_name ZIP file"
$vm_ZipFile = "$env:TEMP\$vm_name.ova"
$vm_HardDiskFilePath = "c:\VMs\Virtual Hard Disks\$vm_name.vhdx"
$swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
#Expand-Archive $vm_ZipFile -DestinationPath $env:TEMP
Start-Process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x $vm_ZipFile -o$env:TEMP\$vm_name\" -Wait

# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\$vm_name\*.vmdk" -Recurse | Select-Object -expand FullName
# run twice, because the first time doesnt seem to work
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$vm_HardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$vm_HardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait

    # Import Virtual Machine
Write-Host "Importing $vm_name"
new-vm -Name $vm_name -VHDPath $vm_HardDiskFilePath -MemoryStartupBytes 4096MB
    # configure NIC
#get-vm -Name $vm_name | Add-VMNetworkAdapter -SwitchName "Private" -IsLegacy $true
# Set all adapters to private
get-vm -Name $vm_name | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "Private"
# Set CPU count
get-vm -Name $vm_name | Set-VMProcessor -Count 2
# Delete %TEMP% files
Remove-Item $vm_ZipFile -Force
Remove-Item "$env:TEMP\$vm_name" -Force -Recurse
    