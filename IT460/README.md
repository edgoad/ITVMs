Based on https://github.com/Azure/azure-devtestlab/blob/master/samples/ClassroomLabs/Scripts/EthicalHacking/Setup-EthicalHacking.ps1

To run:
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"


If multiple reboots needed, restart the script after reboot
