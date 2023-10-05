#!/bin/bash

#5 min plan script
if  [ "$EUID" -ne 0 ]; then 
    echo "User is not root. Skill issue."
    exit 
fi

backups() {
    # BACKUPS AUTHOR: Smash (https://github.com/smash8tap)
    # Make Secret Dir

    echo "Making backups..."
    hid_dir=roboto-mono
    mkdir -p /usr/share/fonts/$hid_dir

    declare -A dirs
    dirs[etc]="/etc"
    dirs[www]="/var/www"
    dirs[lib]="/var/lib"
    for i in "${dirs[@]}"; do
      for key in "${!dirs[@]}"; do
        if [ -d "$i" ] 
        then
          tar -pcvf /usr/share/fonts/$hid_dir/.$key.tar.gz $i > /dev/null  2>&1
          # Rogue backups
          tar -pcvf /var/backups/$key.bak.tar.gz $i > /dev/null  2>&1
        fi
      done
    done
}

common_pack() {
    # Install common packages
    #
    # [  ] Needs to be able to fix sources.list
    # [  ] Prompt user for distro

    echo "Installing common packages..."
    sudo apt update
    sudo apt install git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums -y
}

# Sed sshd_config

sed_ssh() {

    # Don't know how to do this yet :p
    echo "Not finished"
}


bash_rep() {
    echo "Replacing bashrc for new users and root..."
    # Need to make a .bashrc_clean file
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/bashrc > /etc/skel/.bashrc
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/bashrc > /root/.bashrc
}

setup_honeypot() {

    echo "Downloading honeypot..."
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Uncategorized/gouda.sh | sh

    # Figure out sed command

    sed 's|/bin/sh/|/bin/redd|' /etc/passwd
    sed 's|/bin/bash/|/bin/redd|' /etc/passwd

    echo "Adding new admin user blue..."
    useradd blue -m -G sudo 
}





# main

backups
bash_rep
setup_honeypot

# add more here

