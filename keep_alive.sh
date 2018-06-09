#!/usr/bin/env bash

# Script to keep tool up and running
# Reads tool to search for from arguments
# Written by Victor Ansart Oct 2018

#help messages
helpMsg='usage: keep_alive <program_to_search_for>

keep_alive is a tool to check if a program is running and restarts it otherwise
Written by Victor Ansart
'

if [ "$#" -eq 0 ]      #check number of arguments supplied
then
	printf "%s" "$helpMsg"
	exit 1
fi

if [ "$1" == '-h' ] || [ "$1" == '--help' ] # display help
then
	printf "%s" "$helpMsg"
	exit 1
fi

tool="$@"    #get tool to search for from arguments


#check if tool is not running
if ! ps -ax | grep -v "grep" | grep -v "keep_alive" | grep -q "$tool"
then
	#tool not running
	#echo "Not running"
	$tool > /dev/null &      #restart tool in background with no output to stdout
#else
	#echo "Running!"
fi

exit 0
