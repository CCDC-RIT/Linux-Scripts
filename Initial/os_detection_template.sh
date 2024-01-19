#!/bin/bash

##############################################################################
# This is an example of how to use the results of os_detection.sh in your code
# It will fail with an error message if the path of the os.txt file is wrong
# Written by Guac0
##############################################################################

# Import the OS variables
# Needs os_detection.sh to run first
PATH_TO_OS_RESULTS_FILE="./os.txt"
if [ -f $PATH_TO_OS_RESULTS_FILE ] ; then
    source $PATH_TO_OS_RESULTS_FILE
else
    echo "Operating System information file (as produced by os_detection.sh) not found! Exiting..."
    exit
fi

# At this point, the OS variables are set up.
# The available variables are as follows:
    # $OS_NAME is a representation of the name of the OS/distro without spaces
        # Such as 'ubuntu' or 'amazon_linux' (without quotes if that matters)
        # This will be set to 'unknown' if a supported OS is not detected (without quotes if that matters)
    # Each OS has a variable of the OS name in all caps containing a boolean of whether that OS is detected
        # Such as $DEBIAN=true on a debian or ubuntu machine (as ubuntu originates from debian)
    # See os_detection.sh for a full list of supported OSes that can be detected
# The following is an example of how to use them, but you do not need to precisely replicate the below code

if $DEBIAN || $UBUNTU ; then
    # These both use apt as pkg manager
    echo "Detected compatible OS: $OS_NAME"
    echo "Using apt install to install common packages."

    sudo apt update
    sudo apt install curl -y #-y for say yes to everything
elif $REDHAT || $RHEL || $AMZ || $FEDORA; then 
    # These all use YUM (or uses YUM as an alias for the actual one) for package manager
    echo "Detected compatible OS: $OS_NAME"
    echo "Using yum to install common packages."

    sudo yum check-update
    sudo yum install curl -y
elif $ALPINE ; then 
    # This uses apk as pkg manager
    echo "Detected compatible OS: $OS_NAME"
    echo "Using apk to install common packages."

    sudo apk update
    sudo apk add curl #apk automatically has equivalent -y functionality
elif $SLACK ; then 
    # This uses slapt-get as pkg manager
    echo "Detected compatible OS: $OS_NAME"
    echo "Using slapt-get to install common packages."

    #sudo slapt-get update #Not a thing for slapt-get
    sudo slapt-get --install $COMMON_PACKAGES
else
    # Unknown OS. You can choose whether to just exit/do nothing with an error message, or to implement a custom fallback behavior.
    echo "Unsupported or unknown OS detected: $OS_NAME"
fi