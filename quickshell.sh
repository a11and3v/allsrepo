#!/bin/bash

#Simply to automate ssh'ing... I've just typed 192.168.3.205 one too may times

housekeeping(){
	echo "Exiting..."
	unset choice 
	unset prompt
	unset ARRAY
	unset defaults

	exit 0
}

spawn_shell(){
	x-terminal-emulator -e "bash -c \"sshpass -p$password ssh $user@$subnet.$host\"" &
	main
}

main(){
	clear
	echo "Enter last octet of ip [assuming /24]
Hit enter to launch ssh shell...
CTRL+C to exit."

	read -p ":" host
	spawn_shell
}

trap 'housekeeping' INT

defaults="192.168.3 student student"

echo "Enter subnet, username and password [space delimited][ENTER=>$defaults]"
read -p ":" prompt

prompt="${prompt:-$defaults}"

	#Let's try something different here
	IFS=' ' read -ra ARRAY <<< "$prompt"
	subnet=${ARRAY[0]}
	user=${ARRAY[1]}
	password=${ARRAY[2]}

main
