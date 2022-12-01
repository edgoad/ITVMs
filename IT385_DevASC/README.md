# IT 385 DEVASC

## To run:
1. Manually download the CSR ISO csr1000v-universalk9.16.09.05.iso, from

    - https://software.cisco.com/download/home/284364978/type/282046477/release/Fuji-16.9.5 
    - Select the download icon to the right of the following file:
      - **Cisco CSR1000V IOS XE Universal - CRYPTO ISO**
      - csr1000v-universalk9.16.09.05.iso
    - Save the file to **C:\users\student\desktop\LabFiles**
	- **Note:** To download software from cisco.com, you must be an active NetAcad instructor and have a CCO account with the activated NetAcad Maintenance contract.

2. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

## Remaining setup
All remaining install and setup will be performed by the student. Setup can be performed locally on the student's personal computer, except for the labs requireing the CSR1000v
