#!/bin/bash
# Initialise the Kali instance

sudo adduser --shell /bin/bash -m user
echo "user:Automation123" | sudo chpasswd
sudo usermod -aG google-sudoers user
#
sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
sudo service sshd restart
sudo yum install expect -y
#
sudo curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
sudo chmod 755 msfinstall
sudo ./msfinstall
#
sudo curl https://raw.githubusercontent.com/jamesholland-uk/scripts/master/metasploit-initialise-db.sh > metasploit-initialise-db.sh
sudo chmod 755 metasploit-initialise-db.sh
su -c "./metasploit-initialise-db.sh" -s /bin/sh user
#
sudo touch /home/user/.bashrc
sudo echo -e "\n\n+ -- --=[ Pre-canned ]=-- -- +\n\n    ./struts1-exploit.sh\n\n" >> /etc/motd
#
sudo yum install git openssl-devel pam-devel zlib-devel autoconf automake libtool -y
sudo git clone https://github.com/shellinabox/shellinabox.git
cd shellinabox
sudo autoreconf -i
sudo ./configure
sudo make
sudo curl https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/shell-style.css > shell-style.css

su -c "./shellinaboxd -b -q -t --user-css Normal:+shell-style.css" -s /bin/sh user
#./shellinaboxd -b -q -t --user-css Normal:+shell-style.css

sudo yum install nc -y

cd ..
#
sudo curl https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/struts1.rc > /home/user/struts1.rc
sed -i "s/xxyyzz/$1/g" /home/user/struts1.rc
sudo touch /home/user/struts1-exploit.sh
sudo chmod 755 /home/user/struts1-exploit.sh
sudo echo "msfconsole -r struts1.rc" > /home/user/struts1-exploit.sh
#
