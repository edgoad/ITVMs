# IT 385 DEVASC

## To run:
1. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

2. Manually download the DEVASC_VM.OVA and DEVASC_CSR1000v.zip from NetAcad into the Downloads folder

3. Run the following in PowerShell
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/02-VMSetup.ps1" -OutFile $env:TEMP\02-VMSetup.ps1
."$env:Temp\02-VMSetup.ps1"
```

4. Launch DEVASC VM, run the following commands in a terminal
```
sudo vbox-uninstall-guest-additions
sudo sed -i -r 's/name: en\*/name: e\*/' /etc/netplan/01-netcfg.yaml
sudo netplan apply
ip addr
```
Confirm interface eth0 has an ip address


5. Manually download the CSR ISO csr1000v-universalk9.16.09.05.iso, from

    - https://software.cisco.com/download/home/284364978/type/282046477/release/Fuji-16.9.5 
    - Select the download icon to the right of the following file:
      - **Cisco CSR1000V IOS XE Universal - CRYPTO ISO**
      - csr1000v-universalk9.16.09.05.iso
    - Save the file to **C:\users\student\desktop\LabFiles**
	- **Note:** To download software from cisco.com, you must be an active NetAcad instructor and have a CCO account with the activated NetAcad Maintenance contract.

6. Install the CSR1000v VM following the instructions at https://content.cisco.com/chapter.sjs?uri=/searchable/chapter/content/en/us/td/docs/routers/csr1000/software/configuration/b_CSR1000v_Configuration_Guide/b_CSR1000v_Configuration_Guide_chapter_0110.html.xml

7. Once the CSR1000v VM is installed. Unzip the DEVASC_CSR1000v.zip file.
8. Extract CSR1000v_for_VirtualBox.ova using 7zip
9. Configure the CSR1000v VM DVD to use IOSXE_CONFIG.iso
10. Boot CSR1000v, confirm it recieves a configuration.

## Remaining setup
All remaining install and setup will be performed by the student. Setup can be performed locally on the student's personal computer, except for the labs requireing the CSR1000v


**All VMs**
When finished customizing, run the following
```
Get-VM | Stop-VM
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot"
```
Run the following to re-ask for username on first boot
```
$command = 'powershell -Command "& { rename-computer -newname $( $( read-host `"Enter your username:`" ) + \"-\" + $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
```


