# Confirm running as Root
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Install / upgrade packages
apt update
apt install -y python3 python3-pip telnet ftp git openssh-server linux-tools-virtual linux-cloud-tools-virtual xrdp
apt upgrade -y
apt autoremove -y

# Setup Enhanced mode
wget https://raw.githubusercontent.com/Microsoft/linux-vm-tools/master/ubuntu/18.04/install.sh
chmod +x install.sh
./install.sh
# Update for Enhanced mode in Ubuntu 20
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/xrdp.ini

# Lower OpenSSH security level
echo 'KexAlgorithms +diffie-hellman-group-exchange-sha1' >> /etc/ssh/ssh_config
echo 'Ciphers +3des-cbc' >> /etc/ssh/ssh_config

# Clean up
rm ~/*.sh
rm ~/.ssh/known_hosts
rm /home/justincase/.ssh/known_hosts
history -c
