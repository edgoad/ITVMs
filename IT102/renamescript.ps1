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
$newName = $( "$username-" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12)
Rename-Computer -NewName $newName
