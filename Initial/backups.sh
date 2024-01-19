#!/bin/bash

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
    dirs[log]="/var/log"
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

backups