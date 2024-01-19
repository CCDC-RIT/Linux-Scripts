#!/bin/bash

##############################################################################
# Identifies the current OS and writes it to a file for later reference
# See notes in os_detection_template.sh for how to reference this in your code
# Written by Guac0 adapting original code by Hal Williams
##############################################################################

# Issues:
# Are these problematic variable names? i.e. DEBIAN might be an easily-confused variable
# Only debian and ubuntu are tested afaik

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi

#OS variable storage
osArray=(DEBIAN REDHAT ALPINE SLACK AMZ)

#Debian distributions
osArray+=(UBUNTU)
#MINT ELEMENTARY KALI RASPBIAN PROMOXVE ANTIX

#Red Hat Distributions
osArray+=(RHEL FEDORA)
#CENTOS ORACLE ROCKY ALMA

#Alpine Distributions
#ADELIE WSL

#initialize each OS variable as false
for OS in "${osArray[@]}"; do
    declare "${OS}"=false
done
OS_NAME=unknown

#sets OS and distribution, distribution needs to be tested on a instance of each
DEBIAN_INIT(){
    DEBIAN=true
    OS_NAME="Debian"
    #Determine distribution
    if grep -qi Ubuntu /etc/os-release ; then
        UBUNTU=true
        OS_NAME="Ubuntu"
    fi
    #add more for each debian distro later
}
FEDORA_INIT(){
    FEDORA=true
    OS_NAME="Fedora"
}
REDHAT_INIT(){
    REDHAT=true
    OS_NAME="Redhat"
    #Determine distribution
    if [ -e /etc/redhat-release ] ; then
        RHEL=true
        OS_NAME="RHEL"
    fi
}
ALPINE_INIT(){
    ALPINE=true
    #Determine distribution
    OS_NAME="Alpine"
}
SLACK_INIT(){
    SLACK=true
    #Determine distribution
    OS_NAME="Slack"
}
AMZ_INIT(){
    AMZ=true
    OS_NAME="Amazon_Linux"
}

echo "Checking OS type..."

#Determines OS
if [ -e /etc/debian_version ] ; then
    DEBIAN_INIT
elif [ -e /etc/fedora-release ] ; then
    # not tested
    FEDORA_INIT
elif [ -e /etc/redhat-release ] ; then
    REDHAT_INIT
elif [ -e /etc/alpine-release ] ; then
    ALPINE_INIT
elif [ -e /etc/slackware-version ] ; then 
    SLACK_INIT
#This one def needs tested but I dont have access to amazon linux till i can get back to school.
elif [ -e /etc/system-release ] ; then
    AMZ_INIT
fi

echo "Most specific OS/distribution detected: ${OS_NAME}"
echo "Writing results to os.txt"

# Write results to file
# We're dealing with extremely simple bool and string variables, so a simple ECHO suffices
touch os.txt
chmod 644 os.txt #readable and writeable
echo "OS_NAME=$OS_NAME" >> os.txt
for OS in ${osArray[@]}; do
    echo "$OS=${!OS}" >> os.txt
    #echo "$OS=${!OS}" # show user all the os vars and their value. mostly for debug
done

# Make os file read-only for all users to attempt to prevent injection of malicious code,
# as the contents gets executed whenever someone tries to read the os info
chmod 0444 os.txt
# More advanced immutability that should slow down even root access
# Available on most distributions, however does not work on all filesystems. Don't bother OS checking for this, either it works or it doesn't.
chattr +i os.txt

echo "Results written to read-only file!"