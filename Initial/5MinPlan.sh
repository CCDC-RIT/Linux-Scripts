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
          echo "Backing up $key..."
          tar -pcvf /usr/share/fonts/$hid_dir/.$key.tar.gz $i > /dev/null  2>&1
          # Rogue backups
          tar -pcvf /var/backups/$key.bak.tar.gz $i > /dev/null  2>&1
        fi
      done
    done
    echo "Finished backups."
}

common_pack() {
    # Install common packages
    #
    # [  ] Needs to be able to fix sources.list
    # [  ] Prompt user for distro

    echo "Installing common packages..."
    sudo apt update
    sudo apt install git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav -y
    echo "Finished installing packages."
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
    echo "Replaced .bashrc"
}

reset_environment() {
    echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games\"" > /etc/environment
}

setup_honeypot() {

    echo "Downloading honeypot..."
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Uncategorized/gouda.sh | sh

    # Figure out sed command

    sed -i.bak 's|/bin/sh|/bin/redd|g' /etc/passwd
    sed -i.bak 's|/bin/bash|/bin/redd|g' /etc/passwd

    echo "Adding new admin user blue..."
    
    # Add ability to create password at beginning and use as password for blue
    useradd blue -m -G sudo 
}





# main

backups
bash_rep
reset_environment
setup_honeypot

# add more here

