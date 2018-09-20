#!/bin/bash
# Initialise the Kali instance

sudo yum install expect -y
#
sudo curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
sudo chmod 755 msfinstall
sudo ./msfinstall
#
sudo curl https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/sploit-init.sh > sploit-init.sh
sudo chmod 755 sploit-init.sh
sudo ./sploit-init.sh
