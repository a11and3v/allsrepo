#!/bin/bash

housekeeping(){
	echo "Removing tempfiles..."
	echo "$temp1, $temp2"
	rm $temp1 $temp2
	unset device
	exit 0
}

temp1=$(mktemp /tmp/palindrome.XXXXXXXXXX)
temp2=$(mktemp /tmp/palindrome.XXXXXXXXXX)

device=$(grep -E 'Handlers|EV=' /proc/bus/input/devices | \
grep -B1 'EV=120013' | \
grep -Eo 'event[0-9]+')

trap 'housekeeping' INT

while : ; do 
cat /dev/input/$device  > $temp1 &
	while : ; do
	cat /dev/input/$device > $temp2 &
		if [ "$(diff $temp1 $temp2)" ]; then
		xdotool type "hello world "
		pkill cat
		break
		fi
	done
done
