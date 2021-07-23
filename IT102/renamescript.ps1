# Set random computer name in case user closes PS window
$newName = $( "NAN-" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12)
Rename-Computer -NewName $newName 
clear

# Prompt user for username
Write-Host @"

**************************************************
**************************************************
**                                              **
**            Welcome to Azure Labs             **
**                                              **
**************************************************
**************************************************

"@
Write-Host "To get started, please enter your username below`n"
$userName = Read-Host "Enter your username"

# Rename computer using username
$newName = $( "$userName-" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12)
Rename-Computer -NewName $newName
