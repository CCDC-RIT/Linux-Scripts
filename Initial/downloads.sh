# Created by Guac0 using code from vipersniper0501 for CCDC 2024

# Objective:
# Have a central downloader script that'll fetch all the other scripts and etc.
# Also install some common packages and shell stuff

# Usage:
# Note - Tested on Debian 12 and Ubuntu 22.04.03
# 1. Install curl via "sudo apt install curl"
# 2. Obtain this script via "curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/downloads.sh > downloader.sh"
# 3. Run it via "sudo sh downloads" or your equivalent bash execution method
#      If you get an error like "useradd command not found", start a superuser session with "su -l"
# 4. If you get configuration popups, the defaults should likely work fine.
# 5. The script will then automatically delete itself. The installed scripts are located in /home/blue/Linux-Scripts

# Tasks/Questions:
# Where do we download these files to? - blue user home directory in scripts folder
# Migrate downloading and installing honeypot - done
# Download and install packages - done (well, the original ones given to me at least)
# General move from 5MinPlan.sh to this - done
# Add inter-OS interdependency - done

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi


#################################################
# Check what OS we're running on
# Uses logic from inventory.sh by Hal Williams
#################################################

#OS variable initialization
DEBIAN=false
REDHAT=false
ALPINE=false
SLACK=false
AMZ=false

#Debian distributions
UBUNTU=false
#MINT=false
#ELEMENTARY=false
#KALI=false
#RASPBIAN=false
#PROMOXVE=false
#ANTIX=false

#Red Hat Distributions
RHEL=false
#CENTOS=false
#FEDORA=false
#ORACLE=false
#ROCKY=false
#ALMA=false

#Alpine Distributions
#ADELIE=false
#WSL=false

#sets OS and distribution, distribution needs to be tested on a instance of each
DEBIAN() {
    DEBIAN=true
    OS=debian
    #Determine distribution
    if grep -qi Ubuntu /etc/os-release ; then
        UBUNTU=true
        OS=ubuntu
    fi
    #add more for each debian distro later
}
REDHAT() {
    REDHAT=true
    #Determine distribution
    OS=redhat
    if [ -e /etc/redhat-release ] ; then
        RHEL=true
        OS=rhel
    fi
}
ALPINE() {
    ALPINE=true
    OS=alpine
    #Determine distribution
}
SLACK() {
    SLACK=true
    OS=slack
    #Determine distribution
}
AMZ() {
    AMZ=true
    OS=amazon_linux
}

#Determines OS
DEBIAN=false
UBUNTU=false
REDHAT=false
ALPINE=false
SLACK=false
AMZ=false
RHEL=false
if [ -e /etc/debian_version ] ; then
    DEBIAN
elif [ -e /etc/redhat-release ] ; then
    REDHAT
elif [ -e /etc/alpine-release ] ; then
    ALPINE
elif [ -e /etc/slackware-version ] ; then 
    SLACK
#This one def needs tested but I dont have access to amazon linux till i can get back to school.
elif [ -e /etc/system-release ] ; then
    AMZ
else
    echo "Downloader script cannot determine what Operating System this machine is running on!"
    #echo "The script will now exit"
    OS=unknown
    #exit
fi

#################################################
# End OS checking
# Begin main functions declaration
#################################################

unsupported_os() {
    # Currently unused

    echo "The downloader script has successfully identified the OS as $OS, but this OS is not supported."
    echo "The downloader script will now exit."
    exit
}

common_pack() {
    # Install common packages
    #
    # TODO Needs to be able to fix sources.list (red team can point to their own malicious sources)
    # TODO paranoia - what if some of these are already installed with bad/malicious configs? I don't think they get overwritten with the current settings...

    echo "Installing common packages..."
    # curl may be pre-installed in order to fetch this installer script in the first place...
    COMMON_PACKAGES="git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav snoopy auditd"
    
    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS"
        echo "Using apt install to install common packages."

        sudo apt update
        sudo apt install $COMMON_PACKAGES -y #-y for say yes to everything
    elif $REDHAT || $RHEL || $AMZ ; then 
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS"
        echo "Using yum to install common packages."

        sudo yum check-update
        sudo yum install $COMMON_PACKAGES -y
    elif $ALPINE ; then 
        echo "Detected compatible OS: $OS"
        echo "Using apk to install common packages."

        sudo apk update
        sudo apk add $COMMON_PACKAGES #apk automatically has equivalent -y functionality
    elif $SLACK ; then 
        echo "Detected compatible OS: $OS"
        echo "Using slapt-get to install common packages."

        #sudo slapt-get update #Not a thing for slapt-get
        sudo slapt-get --install $COMMON_PACKAGES
    else
        echo "Unsupported or unknown OS detected: $OS"
        read -p "Please enter the command to update the package manager's list of available packages (such as 'apt update'): " PKG_UPDATE < /dev/tty
        read -p "If applicable, add any arguments you wish to add to the update command: " PKG_UPDATE_ARGS < /dev/tty
        read -p "Please enter the command to install a new package (such as 'apt install'): " PKG_INSTALL < /dev/tty
        read -p "If applicable, add any arguments you wish to add to the install command (such as '-y'): " PKG_INSTALL_ARGS < /dev/tty
        #Only execute the commands if they're not empty
        if ! [ -z "$PKG_UPDATE" ];
        then
            #not empty
            if ! [ -z "$PKG_UPDATE_ARGS" ];
            then
                #not empty
                sudo $PKG_UPDATE $PKG_UPDATE_ARGS
            else
                sudo $PKG_UPDATE
            fi
        fi
        if ! [ -z "$PKG_INSTALL" ];
        then
            #not empty
            if ! [ -z "$PKG_INSTALL_ARGS" ];
            then
                #not empty
                sudo $PKG_INSTALL $COMMON_PACKAGES $PKG_INSTALL_ARGS
            else
                sudo $PKG_INSTALL $COMMON_PACKAGE
            fi
        fi
    fi

    echo "Finished installing packages."
}

bash_rep() {
    # Install our own custom bashrc (bash config file) in case red team installed their own malicious one...

    echo "Replacing bashrc for new users and root..."
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/bashrc > /etc/skel/.bashrc
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/bashrc > /root/.bashrc
    echo "Replaced .bashrc"
}

setup_honeypot() {
    # Set up our own shell replacement for all users that just traps them into a honeypot.
    # All users should also have a secure password and etc for security...
    # If a user needs to use shell for legit reasons, you need to manually reset their shell.

    echo "Downloading honeypot..."
    # Download and run the setup script
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Uncategorized/gouda.sh | sh

    # Don't actually install it into /etc/passwd as user hardening script will do that
    #sed -i.bak 's|/bin/sh|/bin/redd|g' /etc/passwd
    #sed -i.bak 's|/bin/bash|/bin/redd|g' /etc/passwd
    echo "Honeypot prepped and placed in /bin/redd"
}

add_admin_user() {
    # Optionally adds a new blue team admin user
    # Call this BEFORE fetch_all_scripts()
    # TODO is this password creation method secure enough?

    # Prompt user for username and password for new admin user
    echo "If you do not wish to make a new blue team admin user, leave it blank and proceed. Recommended name: 'blue'"
    read -p "Please enter name of new blue team admin user (without spaces): " NAME < /dev/tty

    # if given username is not empty, check if name already exists and then securely prompt for a password
    if ! [ -z "$NAME" ];
    then
        # if given username is already in use, exit
        if [ `id -u $NAME 2>/dev/null || echo -1` -ge 0 ]; # i tried a morbillion ways to detect this and this is the only one that works for some reason
        then
            echo 'A user with the provided admin username already exists, re-run this script and pick another one!'
            exit
        fi

        read -s -p "Please enter password to be added to new admin user $NAME: " PASS < /dev/tty
        echo "" #need to start a new line

        # Add ability to create password at beginning and use as password for blue
        echo "Adding new admin user $NAME..."
        #useradd may error in debian as not found. to fix, exit the root session and begin a new one with su -l
        useradd -p "$(openssl passwd -6 $PASS)" $NAME -m -G sudo
    else
        echo "Not adding an admin user due to configuration options suppressing this functionality!"
    fi
}

fetch_all_scripts() {
    # Just download all the scripts to the home folder of the blue team users
    # Call this AFTER blue user is set up! (setup_honeypot)
    # If we didn't make an admin user, just download to the current directory
    if ! [ -z "$NAME" ];
    then
        # If we did make an admin user, then toss the scripts into their home
        git clone https://github.com/CCDC-RIT/Linux-Scripts/ /home/$NAME/Linux-Scripts
        echo "Scripts have been downloaded to /home/$NAME/Linux-Scripts"
    else
        # If we didn't make an admin user, then toss the scripts into the current directory
        git clone https://github.com/CCDC-RIT/Linux-Scripts/
        echo "Scripts have been downloaded to ./Linux-Scripts"
    fi
}

finish() {
    # At end, delete this file as there's no reason to keep it around
    # Shred is probably overkill
    # currentscript="$0"
    echo "Securely shredding '$0'"
    shred -u $0 #this errors with quotes, however, if we don't have quotes then it *might* stop at the first space in the file path and delete that new path
                    # However, our usage case doesn't involve a full path, and it'll work fine when executed from the same directory, or in a full path without a space
}



#################################################
# Main code
#################################################

common_pack
bash_rep
setup_honeypot
add_admin_user
fetch_all_scripts

echo "Downloads script complete!"

# Delete after running. If you need this script again, it'll be in the newly-downloaded script repository under the blue user.
# https://stackoverflow.com/questions/8981164/self-deleting-shell-script
# When your script is finished, exit with a call to the function, "finish":
trap finish EXIT