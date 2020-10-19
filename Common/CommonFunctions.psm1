<#
The MIT License (MIT)
Copyright (c) Microsoft Corporation  
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.  
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
.SYNOPSIS
This script prepares a Windows Server machine to use virtualization.  This includes enabling Hyper-V, enabling DHCP and setting up a switch to allow client virtual machines to have internet access.
#>

[CmdletBinding()]
param(
)

###################################################################################################
#
# PowerShell configurations
#
function Set-PSConfigurations{
    # NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
    #       This is necessary to ensure we capture errors inside the try-catch-finally block.
    $ErrorActionPreference = "Stop"

    # Hide any progress bars, due to downloads and installs of remote components.
    $ProgressPreference = "SilentlyContinue"

    # Ensure we set the working directory to that of the script.
    Push-Location $PSScriptRoot

    # Discard any collected errors from a previous execution.
    $Error.Clear()

    # Configure strict debugging.
Set-PSDebug -Strict
}

###################################################################################################
#
# Handle all errors in this script.
#

trap {
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message) {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe script failed to run.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Functions used in this script.
#             

<#
.SYNOPSIS
Returns true is script is running with administrator privileges and false otherwise.
#>
function Get-RunningAsAdministrator {
    [CmdletBinding()]
    param()
    
    $isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    Write-Verbose "Running with Administrator privileges (t/f): $isAdministrator"
    return $isAdministrator
}

<#
.SYNOPSIS
Returns true is current machine is a Windows Server machine and false otherwise.
#>
function Get-RunningServerOperatingSystem {
    [CmdletBinding()]
    param()

    return ($null -ne $(Get-Module -ListAvailable -Name 'servermanager') )
}

<#
.SYNOPSIS
Enables Hyper-V role, including PowerShell cmdlets for Hyper-V and management tools.
#>
function Install-HypervAndTools {
    [CmdletBinding()]
    param()

    if (Get-RunningServerOperatingSystem) {
        Install-HypervAndToolsServer
    } else
    {
        Install-HypervAndToolsClient
    }
}

<#
.SYNOPSIS
Enables Hyper-V role for server, including PowerShell cmdlets for Hyper-V and management tools.
#>
function Install-HypervAndToolsServer {
    [CmdletBinding()]
    param()

    
    if ($null -eq $(Get-WindowsFeature -Name 'Hyper-V')) {
        Write-Error "This script only applies to machines that can run Hyper-V."
    }
    else {
        Write-Output "Installing Hyper-V, if needed."
        $roleInstallStatus = Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
        if ($roleInstallStatus.RestartNeeded -eq 'Yes') {
            Write-Error "Restart required to finish installing the Hyper-V role .  Please restart and re-run this script."
            Exit
        }  
    } 

    # Install PowerShell cmdlets
    $featureStatus = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell
    if ($featureStatus.RestartNeeded -eq $true) {
        Write-Error "Restart required to finish installing the Hyper-V PowerShell Module.  Please restart and re-run this script."
    }
}

<#
.SYNOPSIS
Enables Hyper-V role for client (Win10), including PowerShell cmdlets for Hyper-V and management tools.
#>
function Install-HypervAndToolsClient {
    [CmdletBinding()]
    param()

    
    if ($null -eq $(Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-All')) {
        Write-Error "This script only applies to machines that can run Hyper-V."
    }
    else {
        Write-Output "Installing Hyper-V, if needed."
        $roleInstallStatus = Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-All'
        if ($roleInstallStatus.RestartNeeded) {
            Write-Error "Restart required to finish installing the Hyper-V role .  Please restart and re-run this script."
            Exit
        }

        $featureEnableStatus = Get-WmiObject -Class Win32_OptionalFeature -Filter "name='Microsoft-Hyper-V-Hypervisor'"
        if ($featureEnableStatus.InstallState -ne 1) {
            Write-Error "This script only applies to machines that can run Hyper-V."
            goto(finally)
        }

    } 
}

<#
.SYNOPSIS
Enables DHCP role, including management tools.
#>
function Install-DHCP {
    [CmdletBinding()]
    param()
   
    if ($null -eq $(Get-WindowsFeature -Name 'DHCP')) {
        Write-Error "This script only applies to machines that can run DHCP."
    }
    else {
        $roleInstallStatus = Install-WindowsFeature -Name DHCP -IncludeManagementTools
        if ($roleInstallStatus.RestartNeeded -eq 'Yes') {
            Write-Error "Restart required to finish installing the DHCP role .  Please restart and re-run this script."
        }  
    } 

    # Tell Windows we are done installing DHCP
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
}

<#
.SYNOPSIS
Funtion will find object in given list with specified property of the specified expected value.  If object cannot be found, a new one is created by executing scropt in the NewObjectScriptBlock parameter.
.PARAMETER PropertyName
Property to check with looking for object.
.PARAMETER ExpectedPropertyValue
Expected value of property being checked.
.PARAMETER List
List of objects in which to look.
.PARAMETER NewObjectScriptBlock
Script to run if object with the specified value of specified property name is not found.

#>
function Select-ResourceByProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$PropertyName ,
        [Parameter(Mandatory = $true)][string]$ExpectedPropertyValue,
        [Parameter(Mandatory = $false)][array]$List = @(),
        [Parameter(Mandatory = $true)][scriptblock]$NewObjectScriptBlock
    )
    
    $returnValue = $null
    $items = @($List | Where-Object $PropertyName -Like $ExpectedPropertyValue)
    
    if ($items.Count -eq 0) {
        Write-Verbose "Creating new item with $PropertyName =  $ExpectedPropertyValue."
        $returnValue = & $NewObjectScriptBlock
    }
    elseif ($items.Count -eq 1) {
        $returnValue = $items[0]
    }
    else {
        $choice = -1
        $choiceTable = New-Object System.Data.DataTable
        $choiceTable.Columns.Add($(new-object System.Data.DataColumn("Option Number")))
        $choiceTable.Columns[0].AutoIncrement = $true
        $choiceTable.Columns[0].ReadOnly = $true
        $choiceTable.Columns.Add($(New-Object System.Data.DataColumn($PropertyName)))
        $choiceTable.Columns.Add($(New-Object System.Data.DataColumn("Details")))
           
        $choiceTable.Rows.Add($null, "\< Exit \>", "Choose this option to exit the script.") | Out-Null
        $items | ForEach-Object { $choiceTable.Rows.Add($null, $($_ | Select-Object -ExpandProperty $PropertyName), $_.ToString()) } | Out-Null

        Write-Host "Found multiple items with $PropertyName = $ExpectedPropertyValue.  Please choose on of the following options."
        $choiceTable | ForEach-Object { Write-Host "$($_[0]): $($_[1]) ($($_[2]))" }

        while (-not (($choice -ge 0 ) -and ($choice -le $choiceTable.Rows.Count - 1 ))) {     
            $choice = Read-Host "Please enter option number. (Between 0 and $($choiceTable.Rows.Count - 1))"           
        }
    
        if ($choice -eq 0) {
            Write-Error "User cancelled script."
        }
        else {
            $returnValue = $items[$($choice - 1)]
        }
          
    }

    return $returnValue
}

<#
.SYNOPSIS
Funtion will download file from specified url.
.PARAMETER DownloadUrl
Url where to get file.
.PARAMETER TargetFilePath
Path where download file will be saved.
.PARAMETER SkipIfAlreadyExists
Skip download if TargetFilePath already exists.
#>
function Get-WebFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$DownloadUrl ,
        [Parameter(Mandatory = $true)][string]$TargetFilePath,
        [Parameter(Mandatory = $false)][bool]$SkipIfAlreadyExists = $true
    )

    Write-Verbose ("Downloading installation files from URL: $DownloadUrl to $TargetFilePath")
    $targetFolder = Split-Path $TargetFilePath

    #See if file already exists and skip download if told to do so
    if ($SkipIfAlreadyExists -and (Test-Path $TargetFilePath)) {
        Write-Verbose "File $TargetFilePath already exists.  Skipping download."
        return $TargetFilePath
        
    }

    #Make destination folder, if it doesn't already exist
    if ((Test-Path -path $targetFolder) -eq $false) {
        Write-Verbose "Creating folder $targetFolder"
        New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null
    }

    #Download the file
    for ($i = 1; $i -le 5; $i++) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; # Enable TLS 1.2 as Security Protocol
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($DownloadUrl, $TargetFilePath)
            Write-Verbose "File $TargetFilePath download."
            return $TargetFilePath
        }
        catch [Exception] {
            Write-Verbose "Caught exception during download..."
            if ($_.Exception.InnerException) {
                $exceptionMessage = $_.InnerException.Message
                Write-Verbose "InnerException: $exceptionMessage"
            }
            else {
                $exceptionMessage = $_.Message
                Write-Verbose "Exception: $exceptionMessage"
            }
        }
    }
    Write-Error "Download of $DownloadUrl failed $i times. Aborting download."
}

<#
.SYNOPSIS
Invokes process and waits for process to exit.
.PARAMETER FileName
Name of executable file to run.  This can be full path to file or file available through the system paths.
.PARAMETER Arguments
Arguments to pass to executable file.
.PARAMETER ValidExitCodes
List of valid exit code when process ends.  By default 0 and 3010 (restart needed) are accepted.
#>
function Invoke-Process {
    [CmdletBinding()]
    param (
        [string] $FileName = $(throw 'The FileName must be provided'),
        [string] $Arguments = '',
        [Array] $ValidExitCodes = @()
    )

    Write-Host "Running command '$FileName $Arguments'"

    # Prepare specifics for starting the process that will install the component.
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        Arguments              = $Arguments
        CreateNoWindow         = $true
        ErrorDialog            = $false
        FileName               = $FileName
        RedirectStandardError  = $true
        RedirectStandardInput  = $true
        RedirectStandardOutput = $true
        UseShellExecute        = $false
        Verb                   = 'runas'
        WindowStyle            = [System.Diagnostics.ProcessWindowStyle]::Hidden
        WorkingDirectory       = $PSScriptRoot
    }

    # Initialize a new process.
    $process = New-Object System.Diagnostics.Process
    try {
        # Configure the process so we can capture all its output.
        $process.EnableRaisingEvents = $true
        # Hook into the standard output and error stream events
        $errEvent = Register-ObjectEvent -SourceIdentifier OnErrorDataReceived $process "ErrorDataReceived" `
            `
        {
            param
            (
                [System.Object] $sender,
                [System.Diagnostics.DataReceivedEventArgs] $e
            )
            foreach ($s in $e.Data) { if ($s) { Write-Host $err $s -ForegroundColor Red } }
        }
        $outEvent = Register-ObjectEvent -SourceIdentifier OnOutputDataReceived $process "OutputDataReceived" `
            `
        {
            param
            (
                [System.Object] $sender,
                [System.Diagnostics.DataReceivedEventArgs] $e
            )
            foreach ($s in $e.Data) { if ($s -and $s.Trim('. ').Length -gt 0) { Write-Host $s } }
        }
        $process.StartInfo = $startInfo;
        # Attempt to start the process.
        if ($process.Start()) {
            # Read from all redirected streams before waiting to prevent deadlock.
            $process.BeginErrorReadLine()
            $process.BeginOutputReadLine()
            # Wait for the application to exit for no more than 5 minutes.
            $process.WaitForExit(300000) | Out-Null
        }
        # Ensure we extract an exit code, if not from the process itself.
        $exitCode = $process.ExitCode
        # Determine if process requires a reboot.
        if ($exitCode -eq 3010) {
            Write-Host 'The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.'
        }
        elseif ($ValidExitCodes.Contains($exitCode)) {
            Write-Host "$FileName exited with expected valid exit code: $exitCode"
            # Override to ensure the overall script doesn't fail.
            $LASTEXITCODE = 0
        }
        # Determine if process failed to execute.
        elseif ($exitCode -gt 0) {
            # Throwing an exception at this point will stop any subsequent
            # attempts for deployment.
            throw "$FileName exited with code: $exitCode"
        }
    }
    finally {
        # Free all resources associated to the process.
        $process.Close();
        # Remove any previous event handlers.
        Unregister-Event OnErrorDataReceived -Force | Out-Null
        Unregister-Event OnOutputDataReceived -Force | Out-Null
    }
}
function New-Shortcut {}

function Install-7Zip{
    Write-Host "Installing 7Zip, if needed"
    # Install 7-Zip
    $url = "https://www.7-zip.org/a/7z1900-x64.msi"
    $output = $(Join-Path $env:TEMP '/7zip.msi')
    (new-object System.Net.WebClient).DownloadFile($url, $output)
    #Invoke-Process -FileName "msiexec.exe" -Arguments "/i $output /quiet"
    Start-Process $output -ArgumentList "/qn" -Wait
}

function Set-AutoLogout{
    # Set RDP idle logout (via local policy)
    # The MaxIdleTime is in milliseconds; by default, this script sets MaxIdleTime to 1 minutes.
    $maxIdleTime = 10 * 60 * 1000
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value $maxIdleTime -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value $maxIdleTime -Type "Dword" -Force
    #Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value 600000 -Type "Dword"

    # enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Setup idle-logoff (https://github.com/lithnet/idle-logoff/)
    $LocalTempDir = $env:TEMP
    $InstallFile = "lithnet.idlelogoff.setup.msi"
    $url = "https://github.com/lithnet/idle-logoff/releases/download/v1.1.6999/lithnet.idlelogoff.setup.msi"
    $output = "$LocalTempDir\$InstallFile"

    (new-object System.Net.WebClient).DownloadFile($url, $output)
    Start-Process $output -ArgumentList "/qn" -Wait

    # Configure idle-logoff timeout
    New-Item -Path "HKLM:\SOFTWARE\Lithnet"
    New-Item -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Action" -Value 2 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Enabled" -Value 1 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IdleLimit" -Value 10 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IgnoreDisplayRequested" -Value 1 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningEnabled" -Value 1 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningMessage" -Value "Your session has been idle for too long, and you will be logged out in {0} seconds" -Type "String" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningPeriod" -Value 60 -Type "Dword" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Lithnet.idlelogoff -Value '"C:\Program Files (x86)\Lithnet\IdleLogoff\Lithnet.IdleLogoff.exe" /start' -Force


}

function Set-HypervDefaults{
    New-Item -ItemType Directory -Path c:\VMs -Force
    New-Item -ItemType Directory -Path "c:\VMs\Virtual Hard Disks" -Force

    # Create virtual switch
    # Set switch as Private -- no routing to the internet
    if ((Get-VMSwitch | Where-Object -Property Name -EQ "Private").count -eq 0)
    {
        write-host "Creating Private VMswitch"
        New-VMSwitch -SwitchType Private -Name Private
    }

    # Add Hyper-V shortcut
    $Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($(Join-Path "c:\users\public\Desktop" "Hyper-V Manager.lnk"))
    $Shortcut.TargetPath = "$env:SystemRoot\System32\virtmgmt.msc"
    $Shortcut.Save()


    # Setup Hyper-V default file locations
    Set-VMHost -VirtualHardDiskPath "C:\VMs"
    Set-VMHost -VirtualMachinePath "C:\VMs"
    Set-VMHost -EnableEnhancedSessionMode:$true

    Add-DefenderExclusions
}

function Install-Starwind{
    #Install starwind converter
    Write-Host "Installing Starwind V2V Converter, if needed"
    $swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
    if (-not (Test-Path $swcExePath)){
        #Main download page is at https://www.starwindsoftware.com/download-starwind-products#download, choose 'Starwind V2V Converter'.
        $url = "https://www.starwindsoftware.com/tmplink/starwindconverter.exe"
        $output = $(Join-Path $env:TEMP 'starwindconverter.exe')
        (new-object System.Net.WebClient).DownloadFile($url, $output)
        Start-Process $output -ArgumentList "/verysilent" -Wait
    }
}

function Set-DesktopDefaults{
    # setup bginfo
    #Download bginfo
    New-Item -ItemType Directory -Path c:\bginfo -Force
    $url = "https://live.sysinternals.com/Bginfo.exe"
    $output = "C:\bginfo\Bginfo.exe"

    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $output

    #Download default.bgi
    $url = "https://github.com/edgoad/ITVMs/raw/master/default.bgi"
    $output = "C:\bginfo\default.bgi"
    (new-object System.Net.WebClient).DownloadFile($url, $output)

    # Set autorun
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"

    # install chrome
    $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object    System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

}
function Clear-TempFiles{
    Set-Location "C:\Windows\Temp"
    Remove-Item * -recurse -force

    Set-Location "C:\Windows\Prefetch"
    Remove-Item * -recurse -force

    Set-Location "C:\Documents and Settings"
    Remove-Item ".\*\Local Settings\temp\*" -recurse -force

    Set-Location "C:\Users"
    Remove-Item ".\*\Appdata\Local\Temp\*" -recurse -force
}

function Add-DefenderExclusions{
    Add-MpPreference -ExclusionExtension "iso","vhdx","vmdk"
}