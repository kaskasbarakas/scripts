#!/bin/bash

if (( $EUID != 0 )); then
    echo "This script must be run as root. Type in 'sudo $0' to run it as root."
    exit 1
fi


usage()
{
cat<<EOF
usage : $0 options


This script is for quickly getting Tor relays online without any 3rd party software.

example : $0 -d Debian

OPTIONS:
 -h Shows this message
 -d distro example : -d gentoo or -d debian

Distro's included : Gentoo, Debian, Ubuntu, Arch
EOF
}


S="\e[32m"
F="\e[31m"
B="\e[39m"

# here we will check the key if it isn't a valid key then script will exit.

gpg_keyadd() {
    gpg --keyserver keys.gnupg.net --recv 886DDD89
    try=`gpg --fingerprint 886DDD89 | grep fingerprint | tr -d ' ' | sed 's/Keyfingerprint=//g'`
    if [ $try != "A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89" ]
    then
        echo -e "["$F"-"$B"] not right key"
        exit 1
    else
        echo -e "["$S"+"$B"] key is valid !!!"
        gpg --export $try | sudo apt-key add -
        apt-get update
        apt-get install tor deb.torproject.org-keyring
        return
    fi
}

# speaks for itself i hope

distro()
{
    if [ $DISTRO = "Debian" -o "debian" ] # Debian installation here ( possibly in their repos )
	then
        echo -e "# This is Tor official repos
        deb http://deb.torproject.org/torproject.org jessie main
        deb-src http://deb.torproject.org/torproject.org jessie main" > /etc/apt/sources.list.d/tor.list
        echo -e "["$S"+"$B"] succesful added Tor repos"
        gpg_keyadd
	elif [ $DISTRO = "Gentoo" -o "gentoo" ]			# For our Gentoo lovers it's in the portage tree
	then
		echo "We are going to emerge Tor"
		echo "net-misc/tor seccomp tor-hardening" >> /etc/portage/package.use
		emerge -av net-misc/tor
	elif [ $DISTRO = "Ubuntu" -o "ubuntu" ] # Ubuntu setup here
	then
        version=`lsb_release -c | grep Codename | sed 's/Codename://g' | tr -d " \t"`
        if [ $version = "xenial" ]
        then
            echo -e "# This is Tor official repos for xenial
            deb http://deb.torproject.org/torproject.org xenial main
            deb-src http://deb.torproject.org/torproject.org xenial main" > /etc/apt/sources.list.d/tor.list
            gpg_keyadd
        elif [ $version = "trusty" ]
        then
            echo -e " # This is Tor official repos for trusty
            deb http://deb.torproject.org/torproject.org trusty main
            deb-src http://deb.torproject.org/torproject.org trusty main" > /etc/apt/sources.list.d/tor.list
            gpg_keyadd
        else
            echo -e "["$F"-"$B"] failed you are not using LTS versions of ubuntu"
        fi
    elif [ $DISTRO = "Arch" -o "arch" ]
    then
	pacman -S tor
    else
        echo -e "["$F"-"$B"] failed please use one of the following : Debian, Gentoo, Ubuntu, Arch"
        exit 1
	fi
}


while getopts ":d:h" SUSAS;
do
	case $SUSAS in
	h)
	 usage
	 exit 1
	 ;;
	d)
	 DISTRO=$OPTARG
	 distro
	;;
	\?) valid=0
	 echo "An invalid option has been entered: $OPTARG"
	 usage
	 exit 1
	;;
	:)  valid=0
	 echo "The additional argument for option $OPTARG was omitted." >&2
	;;
     esac
done


