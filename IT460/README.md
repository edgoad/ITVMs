# IT 460 Ethical Hacking / Pentest+ labs
Based on https://github.com/Azure/azure-devtestlab/blob/master/samples/ClassroomLabs/Scripts/EthicalHacking/Setup-EthicalHacking.ps1

## To run:
```
Invoke-WebRequest "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/01-MainSetup.ps1" -OutFile $env:TEMP\01-MainSetup.ps1
."$env:Temp\01-MainSetup.ps1"
```

If multiple reboots needed, restart the script after reboot


## Post-Setup tasks
**Desktop**
1. timezone
2. background

**KALI VM**
1. Full Install
   - Username/Password: justincase:Password01
2. Configure Network
   - Internal Network
     - IP: 192.168.0.10/24
     - GW: 192.168.0.250
     - DNS: 8.8.8.8
   - Private Network
     - IP: 192.168.38.10/24
     - GW: 192.168.38.1
3. Screen Resolution issues
   - Inside the Kali VM, run the following:
```
git clone https://github.com/mimura1133/linux-vm-tools
chmod 0755 linux-vm-tools/kali/2020.x/install.sh
sudo linux-vm-tools/kali/2020.x/install.sh
```
   - Shutdown Kali, then in PowerShell
```Set-VM "Kali Linux" -EnhancedSessionTransportType HvSocket```

**Metasploitable VM**
1. Configure Network
   - Private Network
     - IP: 192.168.38.30/24
     - GW: 192.168.38.1
