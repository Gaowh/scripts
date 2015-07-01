#!/bin/sh

help="
	-s , set
	-c , clear
	-h , hostname
	-d , gateway device

	can't use -s with -c

"
while getopts :sch:d: opt
do
	case "$opt" in
	
	s)
		if [ -z $cmd ]; then
			cmd=s
		else 
			echo "can't use -s with -c"
			echo $help
			exit
		fi;;

	c)
		if [ -z $cmd ]; then
			cmd=c
		else
			echo "can't use -c whth -s"
			echo $help
			exit
		fi;;

	h)
		hostname=$OPTARG
		echo $hostname;;
	d)
		dev=$OPTARG
		echo $dev;;

	h)	
		echo $help
		exit;;
	esac
done

if [ -z $hostname ] ; then
	
	echo "you must specified hostname use -h"
	exit
fi

if [ -z $dev ] ; then
	
	dev=br-lan
fi

echo $hostname $dev

gateway=`ifconfig $dev | sed -n '2p' | awk '{print $2}' | awk -F: '{print $2}'`
echo $gateway

echo $hostname/$gateway

realname=`echo $hostname | awk -F. '{
	if(NF == 2){
		print $1
	}
	else if(NF == 3){
		print $2
	}
}'`

if [ -z $realname ] ; then
	echo "you specified a wrong hostname"
	exit
fi
echo $realname

if [ -z $cmd ] ;then
	cmd=s
fi

if [ "$cmd" == "c" ] ; then
	iptables -t nat -D PREROUTING -p udp --dport 53 -m string --string "$realname" --algo kmp\
	-j DNAT --to-destination $gateway:53 

	sed -i '/address=\/'$hostname'\/'$gateway'/d' /etc/dnsmasq.conf  

else
	iptables -t nat -I PREROUTING -p udp --dport 53 -m string --string "$realname" --algo kmp\
	-j DNAT --to-destination $gateway:53 

	echo "address=/$hostname/$gateway" >> /etc/dnsmasq.conf
fi

killall dnsmasq

/usr/sbin/dnsmasq -C /var/etc/dnsmasq.conf -k &
