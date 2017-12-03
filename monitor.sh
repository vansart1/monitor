#!/usr/bin/env bash

# Script to monitor server performance and send alert when needed
# Written by Victor Ansart May 2018

###########-variables-##########

#who to send notification emails to
#sendAddress="vansart1@gmail.com"

#time to sleep between loops in MINUTES
#sleep_time=1

#time to wait for another alert to be sent in HOURS
#alert_time_interval=5


############## initialization ##############

#location and name of configuration file
conf_file='/usr/local/etc/monitor/monitor.conf'

#location and name of overall monitor logfile
logfile="/usr/local/var/log/monitor.log"

#location and name of log data in csv format
csv_log="/usr/local/var/log/monitor_stats.csv"


## check conf file to make sure it has no nefarious input
# commented lines, empty lines und lines such as var_name='var_value' are valid
syntax_check="^\s*#|^\s*$|^[a-zA-Z0-9_]+='[a-zA-Z0-9_@.]*'$"

# check if the file contains undesired characters
if egrep -q -v "${syntax_check}" "$conf_file"; 
then
	echo "Syntax error in config file: ${conf_file}." 
	egrep -vn "${syntax_check}" "$conf_file"
	exit 10
fi
#import config file if no problems
source "${conf_file}"


#help messages
helpMsg='usage: monitor

backup is a tool to monitor server status and alert admin if needed
Written by Victor Ansart
'

################# functions ##################

#write out data to log file with date
#Ex: log "data to write to log"
log()
{
	echo -e "$(date)" "$@" >> "$logfile"
}


################## main script ######################

if [ "$#" -ne 0 ]      #check number of arguments supplied
then
	printf "%s" "$helpMsg"
	exit 1
fi

if [ "$1" == '-h' ] || [ "$1" == '--help' ] # display help
then
	printf "%s" "$helpMsg"
	exit 1
fi

#export variables for editing $PATH so commands can be found
export PATH=/usr/sbin:$PATH 		#so can find diskutil and command
export PATH=/usr/local/bin:$PATH  				#so can find email command


alert_level=100
warn_level=20

notification_level=0
previous_notification_level=0
last_alert_time=0


while : 	#infine loop
do
	notification_level=$(($previous_notification_level / 10)) #start notification level with weight from previous run
	message="Status for $HOSTNAME : \\n"


	##### looking at CPU
	text="\\nCPU: \\n"
	message+="$text"
	printf "$text"

	cpu_used=$(ps -A -o %cpu | awk '{ cpu += $1} END {print cpu}')
	cpu_used=${cpu_used%.*} #convert from float to int by truncating
	cpu_cores=$(sysctl -n hw.logicalcpu)
	cpu_used=$(($cpu_used / cpu_cores))

	if [[ $cpu_used -gt 90 ]]
	then
		notification_level=$(($notification_level + 100))    #raise level to ALERT
		text="ALERT: Using $cpu_used percent of cpu \\n"
		message+="$text"
		printf "$text"
	elif [[ $cpu_used -gt 80 ]]
	then
		notification_level=$(($notification_level + 50))     #raise level to almost ALERT
		text="WARNING: Using $cpu_used of cpu \\n"
		message+="$text"
		printf "$text"
	elif [[ $cpu_used -gt 70 ]]
	then
		notification_level=$(($notification_level + 10))     #raise level
		text="WARNING: Using $cpu_used of cpu \\n"
		message+="$text"
		printf "$text"
	else
		text="Using $cpu_used percent of cpu \\n"
		message+="$text"
		printf "$text"
	fi



	##### looking at memory pressure
	text="\\nMemory: \\n"
	message+="$text"
	printf "$text"

	mem_pressure=$(sysctl kern.memorystatus_vm_pressure_level | awk '{print $2}')

	if [[ $mem_pressure -eq 1 ]]
	then
		text="Memory pressure: OK \n"
		message+="$text"
		printf "$text"
	elif [[ $mem_pressure -eq 2 ]]
	then
		notification_level=$(($notification_level + 10))     #raise level
		text="Memory pressure: WARNING \n"
		message+="$text"
		printf "$text"
	else
		notification_level=$(($notification_level + 100))     #raise level to ALERT
		text="ALERT: Memory pressure: CRITICAL \n"
		message+="$text"
		printf "$text"
	fi

	#calculate memory used in percent (not relevant to pressure in macs so no issues with it being high)
	mem_used=$(ps -A -o %mem | awk '{ mem += $1} END {print mem}')


	##### looking at disk space
	text="\\nDisk Space: \\n"
	message+="$text"
	printf "$text"

	fs_free_space=$(df | head -n 2 | grep "/" | awk '{print $5}')
	fs_free_space=${fs_free_space//%}
	if [[ "$fs_free_space" -gt 90 ]]
	then
		notification_level=$(($notification_level + 100))     #raise level to ALERT
		text="ALERT: Filesystem is using $fs_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	elif [[ "$fs_free_space" -gt 70 ]]
	then
		notification_level=$(($notification_level + 50))     #raise level to WARNING
		text="WARNING: Filesystem is using $fs_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	else
		text="Filesystem is using $fs_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	fi

	storage_free_space=$(df | grep "Storage" | awk '{print $5}')
	storage_free_space=${storage_free_space//%}
	if [[ "$storage_free_space" -gt 90 ]]
	then
		notification_level=$(($notification_level + 100))    #raise level to ALERT
		text="ALERT: Storage drive is using $storage_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	elif [[ "$storage_free_space" -gt 70 ]]
	then
		notification_level=$(($notification_level + 50))     #raise level to WARNING
		text="WARNING: Storage drive is using $storage_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	else
		text="Storage drive is using $storage_free_space percent of space \\n"
		message+="$text"
		printf "$text"
	fi



	##### looking at RAID
	text="\\nRAID: \\n"
	message+="$text"
	printf "$text"

	raid_output=$(diskutil appleRAID list)

	raid_status=$(echo "$raid_output" | grep "Status:" | awk '{print $2}')

	if [[ "$raid_status" == "Degraded" ]] #RAID is not online and is degraded
	then
		notification_level=$(($notification_level + 100))     #raise level to ALERT
		text="ALERT: RAID array is degraded \\n"
		message+="$text"
		printf "$text"
		if [[ "$raid_output" == *"Missing"* ]] #A volume is missing
		then
			text="A RAID volume is missing \\n"
			message+="$text"
			printf "$text"
		fi
		if [[ "$raid_output" == *"Failed"* ]] #A volume is failed
		then
			text="A RAID volume has failed \\n"
			message+="$text"
			printf "$text"
		fi
		if [[ "$raid_output" == *"Rebuilding"* ]] #A volume is rebuilding
		then
			notification_level=$(($notification_level - 70))     #downgrade from alert to warning
			text="A RAID volume is rebuilding \\n"
			message+="$text"
			printf "$text"
		fi
	elif [[ "$raid_status" == "Online" ]] #RAID is Online and OK
	then
		text="RAID is online \\n"
		message+="$text"
		printf "$text"
	else					#RAID cannot be found!
		notification_level=$(($notification_level + 100))     #raise level to ALERT
		text="ALERT: RAID not found \\n"
		message+="$text"
		printf "$text"
	fi

	text="\\nPrevious machine stress level was $previous_notification_level \\n"
	message+="$text"
	printf "$text"




  
	echo "------------------------"
	current_time=$(date +%s)


	#if [[ $(($current_time - $last_alert_time)) -gt $(($alert_time_interval * 60 )) ]]
	#then
	#	echo $current_time
	#	echo $last_alert_time
	#	echo $alert_time_interval
	#fi
	if [[ $notification_level -ge $alert_level ]] #send alert notification
	then
		subject="ALERT on $HOSTNAME"
		log "$subject"
		log "$message"
		echo "$notification_level"
		printf "Alert level reached"	
		#if now elevated to alert level or last alert is after alert_time_interval
		if [[ $previous_notification_level -lt $alert_level ]] || [[ $(($current_time - $last_alert_time)) -gt $(($alert_time_interval * 60 * 60)) ]]
		then
			html_message=${message//'\n'/'<br>'}  #replace newline with <br> for html
			myemail "$sendAddress" "$subject" "$html_message" 
			last_alert_time=$current_time     #set last_alert_time so alert not sent so soon again
		fi
	elif [[ $notification_level -ge $warn_level ]] #send warning notification
	then
		subject="WARNING on $HOSTNAME"
		log "$subject"
		log "$message"
		echo "$notification_level"
		printf "Warning level reached"	
		if [[ $(($current_time - $last_alert_time)) -gt $(($alert_time_interval * 60 *60)) ]]   #if last alert is later than alert_time_interval
		then
			html_message=${message//'\n'/'<br>'}   #replace newline with <br> for html
			myemail "$sendAddress" "$subject" "$html_message" 
			last_alert_time=$current_time     #set last_alert_time so alert not sent so soon again
		fi
	fi
	echo "------------------------"


	#edit rolling csv log
	date_time=$(date)

	if [ ! -f "$csv_log" ]
	then 
		echo "date_time,CPU,memory,memory_pressure,fs_used_space,storage_used_space,monitor_notification_level" >> "$csv_log"
	fi
	echo "$date_time,$cpu_used,$mem_used,$mem_pressure,$fs_free_space,$storage_free_space,$notification_level" >> "$csv_log"

	#set previous notifiation level
	previous_notification_level="$notification_level"

	#sleep until next loop
    echo "Sleeping for $sleep_time minutes..."
    echo "$sleep_time"
	sleep $(( $sleep_time * 60 ))
done


