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
#sudo curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
#sudo chmod 755 msfinstall
#sudo ./msfinstall
#
#curl https://rpm.metasploit.com/metasploit-omnibus/pkg/metasploit-framework-5.0.1%2B20190110175340~1rapid7-1.el6.x86_64.rpm > metasploit-framework-5.0.1-20190110175340-1rapid7-1.el6.x86_64.rpm
curl https://www.jamoi.co.uk/metasploit-framework.el6.x86_64.rpm > metasploit-framework.el6.x86_64.rpm
sudo yum install metasploit-framework.el6.x86_64.rpm -y
#
sudo curl https://raw.githubusercontent.com/jamesholland-uk/scripts/master/metasploit-v5-initialise-db.sh > metasploit-v5-initialise-db.sh
sudo chmod 755 metasploit-v5-initialise-db.sh
su -c "./metasploit-v5-initialise-db.sh" -s /bin/sh user
#
sudo touch /home/user/.bashrc
sudo echo -e "\n\n+ -- --=[ Pre-canned ]=-- -- +\n\n    ./struts1-exploit.sh\n\n    ./netcat.sh\n\n" >> /etc/motd
#
sudo yum install git openssl-devel pam-devel zlib-devel autoconf automake libtool telnet -y
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
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo curl https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/struts1-k8s.rc > /home/user/struts1-k8s.rc
sed -i "s/xxyyzz/$1/g" /home/user/struts1-k8s.rc
sudo touch /home/user/struts1-exploit.sh
sudo chmod 755 /home/user/struts1-exploit.sh
sudo echo "msfconsole -r struts1-k8s.rc" > /home/user/struts1-exploit.sh
sudo touch /home/user/netcat.sh
sudo chmod 755 /home/user/netcat.sh
sudo echo "sudo nc -lvp 80" > /home/user/netcat.sh
#
