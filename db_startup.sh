#!/bin/bash
# Initialise the Database server
#
sudo locale-gen en_GB.UTF-8
sudo adduser --shell /bin/bash --disabled-password --gecos "" user
echo "user:Automation123" | sudo chpasswd
#
sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
sudo restart ssh
#
sudo apt-get update
#sudo apt-get install tomcat7 tomcat7-admin default-jre apache2 php5 php5-mcrypt php5-mysql php5-xmlrpc php5-gd git unzip -y
#sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
#
