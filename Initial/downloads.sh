# Created by Guac0 using code from vipersniper0501 for CCDC 2024

# Objective:
# Have a central downloader script that'll fetch all the other scripts and etc.
# Also install some common packages and shell stuff

# Usage:
# Note - Tested on Debian 12 and Ubuntu 20.04
# 1. Install curl via "sudo apt install curl"
# 2. Obtain this script via "curl github.com/CCDC-RIT/Linux-Scripts/downloads.sh"
# 3. Run it via "sudo sh downloads" or your equivalent bash execution method
#      If you get an error like "useradd command not found", start a superuser session with "su -l"
# 4. The script will then automatically delete itself. The installed scripts are located in /home/blue/Linux-Scripts

# Tasks/Questions:
# Where do we download these files to? - blue user home directory in scripts folder
# Migrate downloading and installing honeypot - done
# Download and install packages - done (well, the original ones given to me at least)
# General move from 5MinPlan.sh to this - done
# Add inter-OS dependency

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi

common_pack() {
    # Install common packages
    #
    # [  ] Needs to be able to fix sources.list (red team can point to their own malicious sources)
    # [  ] Prompt user for distro (apt update only works on debian-based)
    # curl may be pre-installed in order to fetch this installer script in the first place...

    echo "Installing common packages..."
    sudo apt update
    sudo apt install git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav snoopy auditd -y #-y for say yes to everything
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
    # Install our own shell replacement for all users that just traps them into a honeypot.
    # All users should also have a secure password and etc for security...
    # If a user needs to use shell for legit reasons, you need to manually reset their shell.

    echo "Downloading honeypot..."
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Uncategorized/gouda.sh | sh

    sed -i.bak 's|/bin/sh|/bin/redd|g' /etc/passwd
    sed -i.bak 's|/bin/bash|/bin/redd|g' /etc/passwd

    if  ! [ -z "$NAME" ];
    then
        # Add ability to create password at beginning and use as password for blue
        echo "Adding new admin user $NAME..."
        #useradd may error in debian as not found. to fix, exit the root session and begin a new one with su -l
        useradd -p "$(openssl passwd -6 $PASS)" $NAME -m -G sudo
    else
        echo "Not adding a blue team admin user due to configuration options suppressing this functionality!"
        echo "As you did not create a blue team user, make sure not to get caught by the auto-configured honeypot that has been applied to all accounts!"
    fi
}

fetch_all_scripts() {
    # Just download all the scripts to the home folder of the blue team users
    # Call this AFTER blue user is set up! (setup_honeypot)
    if ! [ -z "$NAME" ];
    then
        # If we did make an admin user, then toss the scripts into their home
        git clone https://github.com/CCDC-RIT/Linux-Scripts/ /home/$NAME
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



# Main

# Prompt user for username and password for new admin user
echo "If you do not wish to make a new blue team admin user, leave it blank and proceed."
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
fi

# Run the above setup functions
common_pack
bash_rep
setup_honeypot
fetch_all_scripts

echo "Downloads script complete!"

# Delete after running. If you need this script again, it'll be in the newly-downloaded script repository under the blue user.
# https://stackoverflow.com/questions/8981164/self-deleting-shell-script
# When your script is finished, exit with a call to the function, "finish":
trap finish EXIT