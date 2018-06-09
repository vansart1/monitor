#!/usr/bin/env bash

#Installs monitor script, sets up log files, and crontab

monitorPath='/usr/local/bin/monitor'

myemailPath='/usr/local/bin/myemail'

keep_alivePath='/usr/local/bin/keep_alive'


#determine if root
if [[ $EUID -eq 0 ]]
then
	echo "Are you sure you want to install as root"
	echo "Installing in 5 seconds..."
	sleep 5
fi


echo "Installing monitor..."

echo "Moving files to appropriate location..."


############### installing program ##############

#check to see if monitor alredy installed
if [ -f "$monitorPath" ] 
then
	echo "monitor is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling monitor..."
    	#Install monitor script in /usr/local/bin
		cp monitor.sh "$monitorPath"
		chmod 755 /usr/local/bin/monitor

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping monitor reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#monitor not installed, so install
	#Install monitor.sh script in /usr/local/bin
	cp monitor.sh "$monitorPath"
	chmod 755 "$monitorPath"
fi

#check to see if monitor was successfully installed
if [ ! -f "$monitorPath" ] 
then
	echo "monitor utility installation failed..."
	echo "Quitting"
	exit 2
fi


############### installing dependencies ##############

###########check to see if keep_alive alredy installed
if [ -f "$keep_alivePath" ] 
then
	echo "Dependency keep_alive is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling keep_alive dependency..."
    	#Install keep_alive script in /usr/local/bin
		cp keep_alive.sh "$keep_alivePath"
		chmod 755 /usr/local/bin/keep_alive

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping keep_alive reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#keep_alive not installed, so install
	#Install keep_alive.sh script in /usr/local/bin
	cp keep_alive.sh "$keep_alivePath"
	chmod 755 "$keep_alivePath"
fi

#check to see if keep_alive was successfully installed
if [ ! -f "$keep_alivePath" ] 
then
	echo "keep_alive dependency installation failed..."
	echo "Quitting"
	exit 2
fi


##########check to see if myemail alredy installed
if [ -f "$myemailPath" ] 
then
	echo "Dependency myemail is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling myemail dependency..."
    	#Install myemail script in /usr/local/bin
		cp myemail.py "$myemailPath"
		chmod 755 /usr/local/bin/myemail

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping myemail reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#myemail not installed, so install
	#Install myemail.sh script in /usr/local/bin
	cp myemail.py "$myemailPath"
	chmod 755 "$myemailPath"
fi

#check to see if myemail was successfully installed
if [ ! -f "$myemailPath" ] 
then
	echo "myemail dependency installation failed..."
	echo "Quitting"
	exit 2
fi


############### setting up crontab ##############

#set up crontab
cronInfo="$(crontab -l)"
if [[ "$cronInfo" = *"/usr/local/bin/monitor"* ]]; 
then
	echo "crontab already modified. Skipping crontab modification..."
else
	#add entries for backup in crontab. 
	(crontab -l 2>/dev/null; echo "#crontab entry for monitor tool") | crontab -			#comment
	(crontab -l 2>/dev/null; echo "@reboot $monitorPath >/dev/null") | crontab -			#start monitor tool at reboot
	(crontab -l 2>/dev/null; echo "0 */1 * * * $keep_alivePath $monitorPath") | crontab -		#run keep_alive tool every hour for monitor

fi



echo "Installation complete!"

exit 0


