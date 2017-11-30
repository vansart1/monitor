#!/usr/bin/env bash

# Script to monitor server performance and send alert when needed
# Written by Victor Ansart

###########-variables-##########


logfile="/usr/local/var/log/monitor.log"

csv_log="/usr/local/var/log/monitor_stats.csv"



###########-functions-##########

#write out data to log file with date
#Ex: log "data to write to log"
log()
{
	echo "$(date)" "$@" >> "$logfile"
}


###########-main-###############


#export variables for editing $PATH so commands can be found
export PATH=/usr/sbin:$PATH 		#so can find diskutil and command
#export PATH=/sbin:$PATH  				#so can find ping command

message="Status for $HOSTNAME : \\n\\n"

notificationLevel=0


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
	notificationLevel=$(($notificationLevel + 100))    #raise level to ALERT
	text="ALERT: Using $cpu_used percent of cpu \\n"
	message+="$text"
	printf "$text"
elif [[ $cpu_used -gt 80 ]]
then
	notificationLevel=$(($notificationLevel + 50))     #raise level to almost ALERT
	text="WARNING: Using $cpu_used of cpu \\n"
	message+="$text"
	printf "$text"
elif [[ $cpu_used -gt 70 ]]
then
	notificationLevel=$(($notificationLevel + 10))     #raise level
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
	notificationLevel=$(($notificationLevel + 10))     #raise level
	text="Memory pressure: WARNING \n"
	message+="$text"
	printf "$text"
else
	notificationLevel=$(($notificationLevel + 100))     #raise level to ALERT
	text="ALERT: Memory pressure: CRITICAL \n"
	message+="$text"
	printf "$text"
fi

#calculate memory used in percent (not relevant to pressure in macs so no issues with it being high)
mem_used=$(ps -A -o %mem | awk '{ mem += $1} END {print mem}')


##### looking at disk space
text="Disk Space: \\n"
message+="$text"
printf "$text"

fs_free_space=$(df | head -n 2 | grep "/" | awk '{print $5}')
fs_free_space=${fs_free_space//%}
if [[ "$fs_free_space" -gt 90 ]]
then
	notificationLevel=$(($notificationLevel + 100))     #raise level to ALERT
	text="ALERT: Filesystem is using $fs_free_space percent of space \\n"
	message+="$text"
	printf "$text"
elif [[ "$fs_free_space" -gt 70 ]]
then
	notificationLevel=$(($notificationLevel + 50))     #raise level to WARNING
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
	notificationLevel=$(($notificationLevel + 100))    #raise level to ALERT
	text="ALERT: Storage drive is using $storage_free_space percent of space \\n"
	message+="$text"
	printf "$text"
elif [[ "$storage_free_space" -gt 70 ]]
then
	notificationLevel=$(($notificationLevel + 50))     #raise level to WARNING
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
	notificationLevel=$(($notificationLevel + 100))     #raise level to ALERT
	text="ALERT: RAID array is degraded \\n"
	msg+="$text"
	printf "$text"
	if [[ "$raid_output" == *"Missing"* ]] #A volume is missing
	then
		text="A RAID volume is missing \\n"
		msg+="$text"
		printf "$text"
	fi
	if [[ "$raid_output" == *"Failed"* ]] #A volume is failed
	then
		text="A RAID volume has failed \\n"
		msg+="$text"
		printf "$text"
	fi
	if [[ "$raid_output" == *"Rebuilding"* ]] #A volume is rebuilding
	then
		notificationLevel=$(($notificationLevel - 70))     #downgrade from alert to warning
		text="A RAID volume is rebuilding \\n"
		msg+="$text"
		printf "$text"
	fi
elif [[ "$raid_status" == "Online" ]] #RAID is Online and OK
then
	text="RAID is online \n"
	message+="$text"
	printf "$text"
else					#RAID cannot be found!
	notificationLevel=$(($notificationLevel + 100))     #raise level to ALERT
	text="ALERT: RAID not found \n"
	message+="$text"
	printf "$text"
fi

echo "------------------------"
if [[ $notificationLevel -ge 100 ]] #send alert notification
then
	subject="ALERT on $HOSTNAME"
	log "$subject"
	log "$message"
	echo "$notificationLevel"
	printf "$subject"	
	printf "$message"
elif [[ $notificationLevel -ge 20 ]] #send warning notification
then
	subject="WARNING on $HOSTNAME"
	log "$subject"
	log "$message"
	echo "$notificationLevel"
	printf "$subject"	
	printf "$message"
fi
echo "$notificationLevel"

echo "------------------------"


date_time=$(date)

if [ ! -f "$csv_log" ]
then 
	echo "date_time,CPU,memory,memory_pressure,fs_used_space,storage_used_space" >> "$csv_log"
fi
	

echo "$date_time,$cpu_used,$mem_used,$mem_pressure,$fs_free_space,$storage_free_space" >> "$csv_log"




