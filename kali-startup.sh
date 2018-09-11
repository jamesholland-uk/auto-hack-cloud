#!/bin/bash
# Initialise the Kali instance

sudo curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
sudo chmod 755 msfinstall
sudo ./msfinstall
