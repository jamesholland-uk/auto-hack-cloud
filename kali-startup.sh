#!/bin/bash
# Initialise the Kali instance

sudo yum install expect -y
#
sudo curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
sudo chmod 755 msfinstall
sudo ./msfinstall
#
sudo curl https://raw.githubusercontent.com/jamesholland-uk/scripts/master/metasploit-initialise-db.sh > metasploit-initialise-db.sh
sudo chmod 755 metasploit-initialise-db.sh
su -c "./metasploit-initialise-db.sh" -s /bin/sh jholland
#
echo "/opt/metasploit-framework/bin/msfconsole" >> ~/.bashrc
