#!/bin/bash
echo "Caught one boys!" >> /var/log/goudapot
ri(){
    current_directory=$(pwd)
    echo -n "root@$HOSTNAME:$current_directory# "
    read -r i

    if [ -n "$i" ]; then
        case "$i" in 
            cd*) # handle cd command
                directory="${i#cd }"
                cd "$directory"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            whoami*) # handle whoami
                echo "root"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            touch*) # handle touch
                echo "Too many open files"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            sed*) # handle sed
                echo "sed: Couldn't re-allocate memory"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            cat*) # handle cat
                echo "cat: Write error"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            vim*)
                echo "vim: File not found/could not be created"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            nano*)
                echo "nano: File not found/could not be created"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            sudo*)
                echo "sudo: timestamp too far in the future"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            su*)
                echo "su: cannot set user id: Resource temporarily unavailable"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            ping*)
                echo "ping: Network unreachable"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            nc*)
                echo "nc: Address already in use"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            ls*)
                echo "ls: too many arguments"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            pwd*)
                ;;
            mkdir*)
                ;;
            rmdir*)
                ;;
            mv*)
                ;;
            cp*)
                ;;
            rm*)
                ;;
            find*)
                ;;
            curl*)
                ;;
            wget*)
                ;;
            man*)
                ;;
            iptables*)
                ;;
            ip*)
                ;;
            *)
                echo "-bash: $i: command not found"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
        esac
    fi; 
    ri # Recursive call to continue reading commands
}
trap "ri" SIGINT SIGTSTP exit; 
ri

