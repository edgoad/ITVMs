# -------------------------------
# Variables
# -------------------------------
$vmEnhanced      = "UbuntuVM"
$vmBasic         = "UbuntuVM-Basic"

$vhddir          = "C:\VMs\Virtual Hard Disks"

$originalVHD     = Join-Path $vhddir "UbuntuVM.vhdx"
$goldVHD         = Join-Path $vhddir "UbuntuVM-GOLD.vhdx"

$enhancedVHD     = Join-Path $vhddir "UbuntuVM-Enhanced.vhdx"
$basicVHD        = Join-Path $vhddir "UbuntuVM-Basic.vhdx"

$checkpointName  = "Initial Checkpoint"

# -------------------------------
# 1. Ensure base VM is OFF
# -------------------------------
if ((Get-VM $vmEnhanced).State -ne "Off") {
    Stop-VM $vmEnhanced -Force
}

# -------------------------------
# 2. Rename original VHDX → GOLD
# -------------------------------
if (Test-Path $originalVHD) {
    Rename-Item -Path $originalVHD -NewName "UbuntuVM-GOLD.vhdx"
    Write-Host "Renamed base VHD to GOLD"
}
else {
    Write-Host "Original VHD not found, assuming already renamed"
}

# -------------------------------
# 3. Create differencing disks
# -------------------------------
if (Test-Path $enhancedVHD) { Remove-Item $enhancedVHD -Force }
if (Test-Path $basicVHD)    { Remove-Item $basicVHD -Force }

New-VHD -Path $enhancedVHD -ParentPath $goldVHD -Differencing
New-VHD -Path $basicVHD    -ParentPath $goldVHD -Differencing

Write-Host "Differencing disks created"

# -------------------------------
# 4. Get source VM hardware config
# -------------------------------
$sourceVM   = Get-VM $vmEnhanced
$vmSwitch   = (Get-VMNetworkAdapter -VMName $vmEnhanced).SwitchName
$cpuCount   = $sourceVM.ProcessorCount
$ramStartup = $sourceVM.MemoryStartup

# -------------------------------
# 5. Create BASIC VM (clone config)
# -------------------------------
if (-not (Get-VM -Name $vmBasic -ErrorAction SilentlyContinue)) {

    New-VM -Name $vmBasic `
           -Generation 2 `
           -MemoryStartupBytes $ramStartup `
           -SwitchName $vmSwitch

    Set-VM -Name $vmBasic -ProcessorCount $cpuCount

    Write-Host "Created VM: $vmBasic with matching config"
}
else {
    Write-Host "VM $vmBasic already exists"
}

# -------------------------------
# 6. Attach disks
# -------------------------------
# Enhanced VM
Get-VMHardDiskDrive -VMName $vmEnhanced | Remove-VMHardDiskDrive -ErrorAction SilentlyContinue
Add-VMHardDiskDrive -VMName $vmEnhanced -Path $enhancedVHD

# Basic VM
Get-VMHardDiskDrive -VMName $vmBasic | Remove-VMHardDiskDrive -ErrorAction SilentlyContinue
Add-VMHardDiskDrive -VMName $vmBasic -Path $basicVHD

Write-Host "Disks attached"

# -------------------------------
# 7. Enable Enhanced Session Mode
# -------------------------------
Set-VMHost -EnableEnhancedSessionMode $true
Set-VM -Name $vmEnhanced -EnhancedSessionTransportType HvSocket

Write-Host "Enhanced Session configured"

# -------------------------------
# 8. Create checkpoints
# -------------------------------
$vmEnhanced, $vmBasic | ForEach-Object {

    # VM must be off for clean checkpoint baseline
    if ((Get-VM $_).State -ne "Off") {
        Stop-VM $_ -Force
    }

    $existing = Get-VMSnapshot -VMName $_ -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $checkpointName }

    if (-not $existing) {
        Checkpoint-VM -VMName $_ -SnapshotName $checkpointName
        Write-Host "Checkpoint created for $_"
    }
    else {
        Write-Host "Checkpoint already exists for $_"
    }
}

# -------------------------------
# 9. Protect GOLD disk
# -------------------------------
Set-ItemProperty -Path $goldVHD -Name IsReadOnly -Value $true

Write-Host "GOLD disk set to read-only"

# -------------------------------
# Done
# -------------------------------
Write-Host "Environment ready."
