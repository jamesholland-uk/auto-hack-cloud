#!/bin/bash
# Initialise the Database server
#
sudo locale-gen en_GB.UTF-8
sudo adduser --shell /bin/bash --disabled-password --gecos "" user
echo "user:Automation123" | sudo chpasswd
sudo usermod -aG google-sudoers user
#
sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
sudo restart ssh
#
sudo apt-get update
sudo apt-get install git unzip -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
#
sudo sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mysql/my.cnf
#
wget https://www.jamoi.co.uk/AutocloudLinux6011475.sh
chmod +x AutocloudLinux6011475.sh
sudo ./AutocloudLinux6011475.sh
while sleep 1; do sudo /opt/traps/bin/cytool checkin; done