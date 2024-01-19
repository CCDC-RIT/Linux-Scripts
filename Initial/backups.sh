#!/bin/bash

backups() {
    # BACKUPS AUTHOR: Smash (https://github.com/smash8tap)
    # Make Secret Dir

    echo "Making backups..."
    hid_dir="/usr/share/fonts/roboto-mono"
    mkdir -p "$hid_dir"

    declare -A dirs
    dirs[etc]="/etc"
    dirs[www]="/var/www"
    dirs[log]="/var/log"

    for key in "${!dirs[@]}"; do
        dir="${dirs[$key]}"
        if [ -d "$dir" ]; then
            echo "Backing up $key..."
            tar -czvf "$hid_dir/$key.tar.gz" -C "$dir" . > /dev/null 2>&1
            # Rogue backups
            tar -czvf "/var/backups/$key.bak.tar.gz" -C "$dir" . > /dev/null 2>&1
        fi
    done

    echo "Finished backups."
}

backups
