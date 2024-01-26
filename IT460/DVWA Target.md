Install Ubuntu desktop - full
sudo apt update
sudo apt upgrade

# install docker
sudo apt install docker.io

# Install DVWA
sudo docker run --restart=always -d -p 80:80 vulnerables/web-dvwa

# Install Juice Shop
sudo docker run --restart=always -d -p 3000:3000 bkimminich/juice-shop

# Checkpoint VM and test
web browser to http://localhost -- opens dvwa
web browser to http://localhost -- opens Juice shop
