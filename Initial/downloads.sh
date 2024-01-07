# Created by Guac0 using code from vipersniper0501 for CCDC 2024

# Objective:
# Have a central downloader script that'll fetch all the other scripts and etc.
# Also install config files to their intended locations

# Usage:
# Obtain this script via "curl ttps://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial"
# 

# Tasks/Questions:
# Where do we download these files to? - blue user home directory in scripts folder
# Migrate downloading and installing honeypot - done
# Download and install packages - done (well, the original ones given to me at least)
# General move from 5MinPlan.sh to this - done
# Add inter-OS dependency

# check for root for installs
if  [ "$EUID" -ne 0 ]; then 
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
    sudo apt install git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav snoopy -y #-y for say yes to everything
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
    
    # Add ability to create password at beginning and use as password for blue
    echo "Adding new admin user blue..."
    useradd -p "$(openssl passwd -6 $PASS)" blue -m -G sudo 
}


# Main

# Prompt user for password for new user "blue"
read -s -p "Please enter password to be added to new user: " PASS < /dev/tty
echo ""

# Run the above setup functions
common_pack
bash_rep
setup_honeypot
