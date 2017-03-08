#!/bin/bash

#Plan on making this a standalone script...

echo "Hit [CTRL+C] to stop at any time"
echo "Press any key to continue"
read -n 1 -s
echo "Starting..."
updates=0 

#Infinite loop
while : 
do 

#A counter of sorts
updates=$((updates + 1))

#To find total execution time
start_time=$(date +%s)

#Good old nmap(Used awk this time, yay)
nmap -p22 $subnet.$range -oG - 1>$buffer
grep 'open' $buffer | awk {'print $2'} >$tempfile

#Same as main script but without a loop to verify since it already is ($own_ip_excep --> flag)
if [ $own_ip_excep ]; then
	sed "s/$own_ip//" $tempfile >$buffer
	sed '/^$/d' $buffer >$tempfile
fi

#Same as above but for the addtional ip part
if [ $add_ip_excep ]; then 
	for host in $list; do
		sed "s/$host//" $tempfile >$buffer
		sed '/^$/d' $buffer >$tempfile
	done
fi

#No clue as of now what to do with this. 
if [ $verify_user ]; then
	:
fi

end_time=$(date +%s)

clear

echo "Updated list:"
cat $tempfile
echo
echo "$updates update(s) done"
echo "Current update completed in $((end_time - start_time)) s"
echo
echo "Hit [CTRL+C] to stop"	

done 
