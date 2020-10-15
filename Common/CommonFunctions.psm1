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
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Action" -Value 2 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Enabled" -Value 1 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IdleLimit" -Value 10 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IgnoreDisplayRequested" -Value 1 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningEnabled" -Value 1 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningMessage" -Value "Your session has been idle for too long, and you will be logged out in {0} seconds" -Type "String"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningPeriod" -Value 60 -Type "Dword"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Lithnet.idlelogoff -Value '"C:\Program Files (x86)\Lithnet\IdleLogoff\Lithnet.IdleLogoff.exe" /start'


}