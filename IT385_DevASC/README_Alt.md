# Install and setup DevASC VM from base Ubuntu image
## Install Ubuntu VM

Create a Hyper-V VM
 - Gen 2 VM
 - Min 4GB RAM
 - Min 2 CPU

## Configure Ubuntu

Run the following commands to update the system and install dependencies

```shell
sudo apt update ; sudo apt upgrade -y ; sudo apt autoremove
sudo apt install openssh-server ansible python3-pip -y
```
## Run Ansible script

Borrowed from https://github.com/epiecs/devasc-vm-setup

Run the following commands to download and run the devasc playbook
```shell
wget https://raw.githubusercontent.com/edgoad/ITVMs/refs/heads/master/IT385_DevASC/devasc.yaml
ansible-playbook devasc.yaml
```

# Unsure items
Packet Tracer
built in API lab
Other docker images/services
! chromium
! draw.io
ubuntuversion?
