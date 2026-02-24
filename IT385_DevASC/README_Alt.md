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
git clone https://github.com/edgoad/devasc-vm-setup.git
cd devasc-vm-setup
ansible-playbook site.yml
```

    
