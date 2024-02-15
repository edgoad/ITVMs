# Power off ServerHyperV
Get-VM -Name ServerHyperV | Stop-VM

# Set dynamic memory for ServerHV
Get-VM -Name ServerHyperV | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 512MB -StartupBytes 4GB -MaximumBytes 12GB

# Set Virtualization settings
Set-VMProcessor -VMName ServerHyperV -ExposeVirtualizationExtensions $true -count 4
Get-VMNetworkAdapter -VMName ServerHyperV | Set-VMNetworkAdapter -MacAddressSpoofing On

# Power on ServerHyperV
Get-VM -Name ServerHyperV | Start-VM


# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# Install HV
Invoke-Command -VMName ServerHyperV -Credential $cred -ScriptBlock { 
    Write-Output "Installing Hyper-V, if needed."
    $roleInstallStatus = Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
    if ($roleInstallStatus.RestartNeeded -eq 'Yes') {
        Write-Error "\n\nRestart required to finish installing the Hyper-V role .  Please restart and re-run this script.\n\n"
        Restart-Computer -Force
        Exit
    }  
}

# Configure Network
Invoke-Command -VMName ServerHyperV -Credential $cred -ScriptBlock { 
    Write-Output "Creating PrivateNet, if needed."
    if ( ! (Get-VMSwitch | Where-Object Name -eq 'PrivateNet')){
        Write-Host "Creating PrivateNet vswitch"
        New-VMSwitch -SwitchType Private -Name PrivateNet
    } else { Write-Host "  - PrivateNet vSwitch already created" }
}

# Copy ISOs
$vmSession = New-PSSession -VMName ServerHyperV -Credential $cred
Copy-Item -ToSession $vmSession -Path "C:\ISOs\" -Destination "C:\ISOs\" -Force -Recurse

# Create VMs
Invoke-Command -VMName ServerHyperV -Credential $cred -ScriptBlock { 
    # Reset for student created VMs
    New-Item -ItemType Directory -Path c:\VMs -Force
    # Setup Hyper-V default file locations
    Set-VMHost -VirtualHardDiskPath "c:\VMs"
    Set-VMHost -VirtualMachinePath "c:\VMs"
    new-VM -Name InstallCore -MemoryStartupBytes 1GB -BootDevice VHD -NewVHDPath c:\VMs\InstallCore.vhdx -NewVHDSizeBytes 40GB -SwitchName PrivateNet -Generation 2
    new-VM -Name ServerVM1 -MemoryStartupBytes 1GB -BootDevice VHD -NewVHDPath c:\VMs\ServerVM1.vhdx -NewVHDSizeBytes 40GB -SwitchName PrivateNet -Generation 2
    Get-VM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 512MB -StartupBytes 1GB -MaximumBytes 4GB
    Add-VMDvdDrive -VMName ServerVM1 -Path c:\ISOs\W2k22.ISO
}

#######################################################################
#
# Install ServerVM1 before proceeding
#
#######################################################################

# Configure NIC
Invoke-Command -VMName ServerHyperV -Credential $cred -ScriptBlock {  
    $user = "administrator"
    $pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
    Invoke-Command -VMName ServerVM1 -Credential $cred -ScriptBlock { 
        Get-NetAdapter | Rename-NetAdapter -NewName Ethernet0
        New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress "192.168.0.1" -PrefixLength 24
        Set-NetFirewallRule FPS-ICMP4-ERQ-In -Enabled true
    }
}

# shutdown/optimize/snapshot
Invoke-Command -VMName ServerHyperV -Credential $cred -ScriptBlock { 
    # Shutdown VMs
    Get-VM | Stop-VM 

    # Compress / optimize vhds
    $vhds = Get-Item -Path "C:\VMs\Serv*.vhdx"
    Optimize-VHD $vhds -Mode full

    # Set initial snapshot
    Get-VM | Checkpoint-VM -SnapshotName "InitialConfig" 
}