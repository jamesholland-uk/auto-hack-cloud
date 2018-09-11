#!/bin/bash
# Initialise the Linux server

sudo apt-get update
sudo apt-get install tomcat7 tomcat7-admin default-jre unzip -y
# wget https://archive.apache.org/dist/struts/2.5.12/struts-2.5.12-all.zip
# unzip struts-2.5.12-all.zip
# sudo cp struts-2.5.12/lib/* /usr/share/tomcat7/lib/
wget https://repo1.maven.org/maven2/org/apache/struts/struts2-rest-showcase/2.5.12/struts2-rest-showcase-2.5.12.war
sudo cp struts2-rest-showcase-2.5.12.war /var/lib/tomcat7/webapps
sudo service tomcat7 restart
