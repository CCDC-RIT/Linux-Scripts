#######################################################################
# Identifies the current OS and writes it to a file for later reference
# Written by Guac0 using code by Hal Williams
#######################################################################

# To use these stored variable names, add the following:
# source PATH/TO/os.txt
# or (alternate syntax): . PATH/TO/os.txt
# Then, you will have an all-caps variable name of each supported OS with a boolean value of whether it was detected or not
    # Such as $DEBIAN=true
# Additionally, $OS_NAME gives a string representation of the most specific OS/Distribution that was detected
    # Such as $OS_NAME=debian
# Note that this will run os.txt, so be careful if red team modifies it!
    # It's set to read only

# Issues
# Are these problematic variable names?
# I suspect that the initialization of all of them to false links them in some way, causing them all to be set to true when 1 is. will fix later

#OS variable storage
osArray=(DEBIAN REDHAT ALPINE SLACK AMZ)

#Debian distributions
osArray+=(UBUNTU)
#MINT ELEMENTARY KALI RASPBIAN PROMOXVE ANTIX

#Red Hat Distributions
osArray+=(RHEL)
#CENTOS FEDORA ORACLE ROCKY ALMA

#Alpine Distributions
#ADELIE WSL

#initialize each OS variable as false
for OS in "${osArray[@]}"; do
    declare -n "${OS}"=false
    echo "${OS}"
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

echo "OS detected: ${OS_NAME}"
echo "Writing results to os.txt"

# Write results to file
# We're dealing with extremely simple bool and string variables, so a simple ECHO suffices
touch os.txt
chmod 644 os.txt #readable and writeable
echo "OS_NAME=$OS_NAME" >> os.txt
for OS in ${osArray[@]}; do
    echo "$OS=${!OS}" >> os.txt
    echo "$OS=${!OS}"
done

# Make os file read-only for all users to attempt to prevent injection of malicious code,
# as the contents gets executed whenever someone tries to read the os info
chmod 0444 os.txt

echo "Results written to read-only file!"