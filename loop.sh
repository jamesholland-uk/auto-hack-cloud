#!/bin/bash

# Capture all CLI output
#exec &> deploy-log.txt

# Initiate log file
logfile="deploy-log.txt"

# Cron runs every minute, so do this process 28 times, with a 2 second pause, to cover just under a minute of execution
for number in {1..28}
do

# Query databse for jobs which are ready
results=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT JOB FROM jobs WHERE STATUS = 'Ready';") >> $logfile

# Make jobs list from database the stdin
set -- $results

# Take first job
uid=$1

if [ "$uid" != "" ]
	then
	
	# There are jobs ready!
	echo "Job(s) ready" >> $logfile

	# Start the clock
	start=$(date)
    lstart=$(date +%s)
	
	# Set job to deploying status
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET STATUS = 'Deploying' WHERE JOB = '$uid';")

	# Get job attributes
	resgrp=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT RESGRP FROM jobs WHERE JOB = '$uid';") >> $logfile
	message=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT MESSAGE FROM jobs WHERE JOB = '$uid';") >> $logfile
	phone=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT PHONE FROM jobs WHERE JOB = '$uid';") >> $logfile
	email=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT EMAIL FROM jobs WHERE JOB = '$uid';") >> $logfile
	nickname=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT NICKNAME FROM jobs WHERE JOB = '$uid';") >> $logfile
	se=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT SE FROM jobs WHERE JOB = '$uid';") >> $logfile
	subnet=$(mysql -N -u dbuser -psection5 -D azuredb -e "SELECT ID FROM subnetid WHERE NAME = 'here';") >> $logfile
	
	#read -n1 -r -p "Press any key to continue..." key

	# Make sure the subnet is incremented ready for next job, wrapping around 254 as required
	if [ "$subnet" -ge 254 ]
		then
			newsubnet=0
		else
			newsubnet=$((subnet+1))
	fi
	
	#read -n1 -r -p "Press any key to continue..." key

	# Write back the next subnet to the database
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE subnetid SET ID = '$newsubnet' WHERE NAME = 'here';") >> $logfile

	#read -n1 -r -p "Press any key to continue..." key

	# Attribute manipulation as required
	nickname=${nickname//[[:space:]]/}

	echo $resgrp >> $logfile
	echo $message >> $logfile
	echo $phone >> $logfile
	echo $email >> $logfile
	echo $nickname >> $logfile
	echo $subnet >> $logfile
	echo $newsubnet >> $logfile

	#read -n1 -r -p "Press any key to continue..." key

    # Send SMS
	curl -X POST https://textbelt.com/text --data-urlencode phone=$phone --data-urlencode message="Hi $nickname, starting your deployment now..." -d key=8718d364f461d65e09fcc6ee8951b07f9e7a1db4ZIgUg5LpFfhQDAzGaUewvE6i2 >> $logfile
	
	#read -n1 -r -p "Press any key to continue..." key

	# Copy source bootstrap file to working file
	cp bootstrap-orig.xml bootstrap.xml >> $logfile
	cp azureDeploy-orig.json azureDeploy.json >> $logfile
	
	# Replace MOTD and Login-Banner and modify hostname
	sed -i "s/OLD-MSG-MOTD-HERE/$message/g" bootstrap.xml >> $logfile
	sed -i "s/OLD-MSG-LOGIN-HERE/$message/g" bootstrap.xml >> $logfile
	sed -i "s/xxyyzz/$subnet/g" bootstrap.xml >> $logfile
	sed -i "s/VM-FW1/fw-$uid-$nickname/g" azureDeploy.json >> $logfile
	sed -i "s/xxyyzz/$subnet/g" azureDeploy.json >> $logfile

	# Upload bootstrap.xml file - will overwrite any bootstrap.xml file already present
	az storage file upload --share-name autocloud-bootstrap/config --source bootstrap.xml --account-name atailordemomaticshared --account-key xrjXp/Ch8Iip3nfUPaBq2SzLoDNktiixUNFvG0S5hX3i+VuxdxXPh/L4+aV9MEBmR6Qm5yB/A92wGfQP05XUOg== >> $logfile
	
	# Create ResourceGroup
	az group create -l ukwest -n $resgrp >> $logfile
	
	# TESTING - Break if you don't want to continue
	#read -n1 -r -p "Press any key to continue..." key
	
	# Deploy!
	az group deployment create --resource-group $resgrp --template-file azureDeploy.json --parameters @azureDeploy.parameters.json
	deployed=$(date)
	
	# Timers
	ldeployed=$(date +%s)
	deploytime=$((ldeployed - lstart))
	deployminutes=$((deploytime / 60))
	deployseconds=$((deploytime % 60))
	deploytimedesc="$deployminutes minutes and $deployseconds seconds"

	# Set job to bootstrapping
        $(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET STATUS = 'Bootstrapping' WHERE JOB = '$uid';")
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET DEPLOYTIME = '$deploytimedesc' WHERE JOB = '$uid';")

	# Find the public mgmt IP after deployment, and create a URL to test if the VM-Series is up yet
	ip=`az network public-ip list --resource-group $resgrp | grep ipAddress | head -1 | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'`
	untrustip=`az network public-ip list --resource-group $resgrp | grep ipAddress | head -2 | tail -1 | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'`
	echo $ip >> $logfile
	echo $untrustip >> $logfile
	url="https://"$ip
	echo  $url >> $logfile
	
	# Add public mgmt IP to database
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET MGMTIP = '$ip' WHERE JOB = '$uid';")
	
	# Wait for VM-Series to be up (i.e. HTTP code not 000) before opening browser
	while [ `curl --write-out "%{http_code}\n" -k --silent --output /dev/null $url` -eq 000 ]
	do
		echo Waiting...
		sleep 5s
	done
	sleep 15s
	
	# TESTING - Break if you don't want to continue
	#read -n1 -r -p "Press any key to continue..." key
	
	# Timers
        lboot=$(date +%s)
        boottime=$((lboot - ldeployed))
        bootminutes=$((boottime / 60))
        bootseconds=$((boottime % 60))
        bootdesc="$bootminutes minutes and $bootseconds seconds"

	# Set job to configuring
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET STATUS = 'Configuring' WHERE JOB = '$uid';")
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET BOOTTIME = '$bootdesc' WHERE JOB = '$uid';")
	
	# TESTING - Break if you don't want to continue
	#read -n1 -r -p "Press any key to continue..." key
	
	# Get new firewall's XML key
	xmlresp=$(curl -k -X GET 'https://'$ip'/api/?type=keygen&user=panadmin&password=Panadmin001!')
	fwkey=$(sed -ne '/key/{s/.*<key>\(.*\)<\/key>.*/\1/p;q;}' <<< "$xmlresp")
	
	# Get new firewall's serial number
	sysinfo=$(curl -k -X GET 'https://'$ip'/api/?type=op&cmd=<show><system><info></info></system></show>&key='$fwkey)
	serial=$(sed -ne '/serial/{s/.*<serial>\(.*\)<\/serial>.*/\1/p;q;}' <<< "$sysinfo")
	
	# Add new firewall serial number to LSVPN devics list in LSVPN headend firewall
	# Note that LSVPN headend is referred to by internal IP, as it is in the same Azure subnet as this LAMP server - replace with external IP/DNS name if moved to separate subnets
	curl -g -k -X GET 'https://10.123.0.6/api/?type=config&action=set&xpath=/config/devices/entry/vsys/entry/global-protect/global-protect-portal/entry/satellite-config/configs/entry/devices&key=LUFRPT1ZN3FDbEdPVitxeDRoNi9DeG41citraVgyTlE9c0dUWEo4VWJZdnEvM2ptMk9kQzh1VC9YOWNXNmdaSHZhYU95NG1pN2xDcz0=&element=<member>'$serial'</member>'
	curl -k -X GET 'https://10.123.0.6/api/?type=commit&cmd=<commit></commit>&key=LUFRPT1ZN3FDbEdPVitxeDRoNi9DeG41citraVgyTlE9c0dUWEo4VWJZdnEvM2ptMk9kQzh1VC9YOWNXNmdaSHZhYU95NG1pN2xDcz0='

	# Add new firewall serial number to Panorama and commit
	#
	# ** now not needed as I worked out why bootstrap was not adding FW to Rama, Template Stack required, not Template
	#
	# curl -g -k -X GET 'https://51.140.207.127/api/?type=config&action=set&key=LUFRPT1mZXJLTmlMbk1FRzFRdkdPU3B2dVRCQXBrWXc9REVGdXdqcTBraEV2a01sbGxNTThvM3Zmd3dzcVlHTU5RdFNpZk5JNVlRUT0=&xpath=/config/mgt-config/devices/entry[@name='\'''$serial''\'']&element=<hostname>vm-firewall-'$uid'</hostname>'
	#curl -k -X GET 'https://51.140.207.127/api/?type=commit&cmd=<commit></commit>&key=LUFRPT1mZXJLTmlMbk1FRzFRdkdPU3B2dVRCQXBrWXc9REVGdXdqcTBraEV2a01sbGxNTThvM3Zmd3dzcVlHTU5RdFNpZk5JNVlRUT0='
	
	echo ""
	echo "FW KEY" >> $logfile
	echo $fwkey >> $logfile
	echo "SERIAL" >> $logfile
	echo $serial >> $logfile
	echo ""
	
	# Stop the clock
	finish=$(date)
	
	# Record timings
	echo "Start     $start"
	echo "Deployed  $deployed"
	echo "Finished  $finish"
	
	# TESTING - Break if you don't want to continue
	#read -n1 -r -p "Press any key to continue..." key

	# Send SMS
        #curl -X POST https://textbelt.com/text --data-urlencode phone=$phone --data-urlencode message="Hi $nickname, your deployment is done. Here's your firewall: $url Login with username user and password Automation123!" -d key=8718d364f461d65e09fcc6ee8951b07f9e7a1db4ZIgUg5LpFfhQDAzGaUewvE6i2 >> $logfile
	
	# Send Emails
	message_txt=$'Hi '"$nickname"',  Thanks for using the cloud automation demo. Your firewall was deployed to '"$url"' Login with username user and password Automation123!     Kind regards, Palo Alto Networks      (Please contact '"$se"' for more information)'
	mail -a "From: Palo Alto Networks <infosec@panw.co.uk>" -s "Cloud Automation Demo - Palo Alto Networks" $email <<< $message_txt
	mail -a "From: Palo Alto Networks <infosec@panw.co.uk>" -s "Cloud Automation Demo Used by Someone!!!" "jholland@paloaltonetworks.com" <<< $message_txt

	# Timers
        ldone=$(date +%s)
        donetime=$((ldone - lboot))
        doneminutes=$((donetime / 60))
        doneseconds=$((donetime % 60))
        if [ "$doneminutes" == "" ]
        then
		donedesc="$doneseconds seconds"
	else
		donedesc="$doneminutes minutes and $doneseconds seconds"	
	fi
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET DONETIME = '$donedesc' WHERE JOB = '$uid';")

        totaltime=$((ldone - lstart))
        totalminutes=$((totaltime / 60))
        totalseconds=$((totaltime % 60))
        totaldesc="$totalminutes minutes and $totalseconds seconds"
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET TOTALTIME = '$totaldesc' WHERE JOB = '$uid';")

	# Set job to done
	$(mysql -u dbuser -psection5 -D azuredb -e "UPDATE jobs SET STATUS = 'Done' WHERE JOB = '$uid';")
	
	else
	
	# There were no jobs ready, paus for 2 seconds before FOR loop kicks in again
	echo "No jobs ready" >> $logfile
	sleep 2s
fi

# End of for loop as we've done about a minute of checking for jobs, so exit script ready for next cron to initiate

done
exit 0
