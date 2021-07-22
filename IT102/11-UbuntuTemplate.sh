# Confirm running as Root
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Install / upgrade packages
apt update
apt install -y curl wget python3 python3-pip telnet ftp git openssh-server linux-tools-virtual linux-cloud-tools-virtual xrdp apt-transport-https
apt upgrade -y
apt autoremove -y

# Setup Enhanced mode
wget https://raw.githubusercontent.com/Microsoft/linux-vm-tools/master/ubuntu/18.04/install.sh
chmod +x install.sh
./install.sh
# Update for Enhanced mode in Ubuntu 20
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/xrdp.ini



#install VSCode
logger -t devvm "Installing VSCode: $?"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -y code
logger -t devvm "VSCode Installed: $?"
logger -t devvm "Success"

# Clean up
rm ~/*.sh
history -c
