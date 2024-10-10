#!/bin/bash

#################################################################
# Bash Name: Info Extractor					#
# Author: Wan Siew Yik						#
# Description: This script will extract network information	#
# 	       of this device. Information like, internal IP	#
# 	       public IP, and NIC MAC address.			#
#################################################################

# Check is running this script have root permission
# due to find command at "Top 10 Largest Files" section require root permission to search other users' directories
# this script can run without root permission, but it will not able to search other users' directories
# make the script pause for 4 secont for user to read the message
if ! $(sudo -l &> /dev/null); 
then
	echo ''
	echo "[-] Without root permission, you will not able to scan directories belong to other users at 'Top 10 Largest Files' section."
	echo "[+] Script will be running soon."
	echo ''
	sleep 4
fi

figlet "INFO EXTRACTOR"

SUMMARY=""

##########################Private IP############################################
# Get the internal IP by establish a route to Google DNS server
# hide the error incase of not connected to any network
# and assign the result to PRIVATE variable
echo '[+] Getting private IP'
PRIVATE=$(ip -o route get to 8.8.8.8 2>/dev/null | awk '{print $(NF-4)}')
SUMMARY+="Private IP: "

# Check is the PRIVATE under IP address format
# ouput internal IP if PRIVATE under IP address format
# else output error message
if [[ "$PRIVATE" =~ ^([0-9]{1,3}.){3}[0-9]{1,3}$ ]]
then
	echo "[+] Private IP: $PRIVATE"
	SUMMARY+="\t$PRIVATE\n"
else
	echo "[-] Unable to find internal IP."
	SUMMARY+="\tNo internal IP found.\n"
fi

echo ''

##########################Public IP############################################
# Get publis IP by query ifconfig.io web server
# and assign to PUBLIC variable
echo '[+] Getting public IP'
PUBLIC=$(curl -s ifconfig.io)

SUMMARY+="Public IP: "

# Check is the PUBLIC store empty content
# output the public IP if PUBLIC not empty
# else output error message
if [[ -n "$PUBLIC" ]]
then 
	echo "[+] Public IP: $PUBLIC"
	SUMMARY+="\t$PUBLIC\n"
else
	echo "[-] Unable to get public IP."
	SUMMARY+="\tUnable to get public IP.\n"
fi

echo ''

##########################MAC address############################################
# Device might have more than one network interface card (NIC), which mean it can have more than one MAC address
# This script will try to find the one that connected to internet
# If no interface is connect to internet, it will list out all the MAC address
echo '[+] Getting MAC address'
NETWORK_INT=$(ip -o route get to 8.8.8.8 2>/dev/null | awk '{print $(NF-6)}')

if [[ -n $NETWORK_INT ]]
then
	# If one of the NIC connected to internet, get that MAC address
	MAC="$NETWORK_INT: $(ip -o link show $NETWORK_INT | awk '{printf "XX:XX:XX:%s",substr($(NF-2),10)}')"
else
	# If none of the NIC connected to internet, get all the MAC address
	MAC=$(ip -o link show | grep -E "ether|HWaddr" | awk '{printf "%s XX:XX:XX:%s\n",$2,substr($(NF-2),10)}')
fi

echo -e "[+] MAC address:"

# Print out all the MAC address found
echo "$MAC" | awk '{printf "\t[+] %s\n",$0}'

SUMMARY+='MAC address:\n'
SUMMARY+="$(echo "$MAC" | awk '{printf "\t\t[+] %s\n",$0}')\n"

echo ''
##########################Memory Usage############################################
# free: This command will display the memory usage of this machine
# -h: Flag of free that show output to human-readable form
# -t: Flag of free that show the total of RAM + swap
# swap file is temporary data file that store on hard drive when this machine run out of RAM
MEMORY_CMD=$(free -ht)
echo "[+] Current memory usage"
echo "$MEMORY_CMD"

SUMMARY+="Memory Usage:\t$(free -ht | grep Total | awk '{printf "[+] Used: %s [+] Free: %s", $3, $4}')\n\n"


echo ''
##########################Device process (Top 5)############################################
# ps ax: This command will capture the running processes of this moments
# -eo: Flags of ps command to display specified column
# -sort: Falg of ps to specific the order of ps output
# head -n6: show the top 5 included the header
PROCESSES_CMD=$(ps -eo pcpu,pid,user,etime,args --sort=-%cpu | head -n6)
echo "[+] Top 5 running processes (Sorted with CPU usage - high to low)"
echo "$PROCESSES_CMD"

SUMMARY+="Top 5 running processes: \n$PROCESSES_CMD"


echo ''
##########################Active Services############################################
# Get all the service with service command
# User grep to filter only output active service
# Then use a for loop to display all service status

echo '[+] Getting services information'
SERVICES=$(service --status-all | grep + | awk '{print $NF}')
echo '[+] Active services:'

SUMMARY+="\n\nActive service:\n"
for item in $SERVICES
do
	service $item status
	SUMMARY+="\t\t[+] $item:\t$(service $item status | grep Active | awk '{print $3}')\n"
done

SUMMARY+="\n"

echo ''
##########################Top 10 Largest Files############################################
# Use find command to specific only look for file with -type
# and use -printf to format  output the files' size together with the file name
# 2>/dev/null is for hide error message
# Using sort to get the largest file from the output of find command
# -r: Flag that used to sort it with descending order
# -n: State it to compare numerical value
# After this, use head -n10 to get the top 10 from the sorting
# Finally, make it more readable with awk

echo '[+] Generating top 10 latest files report.'
LARGEST_FILE=$(find /home -type f -printf "%s %p\n" 2>/dev/null | sort -rn | head -n10 | awk '{printf "%.1f MB   \t%s\n", $1/1048576, $2}')
echo "[+] Top 10 Largest files:"
echo "$LARGEST_FILE"

SUMMARY+="Top 10 largest files:\n$LARGEST_FILE"

echo ''
echo '######################################Summary##################################################'
echo ''
echo -e "$SUMMARY"
echo ''
echo '###############################################################################################'

