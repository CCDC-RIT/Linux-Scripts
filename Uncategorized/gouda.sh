#!/bin/bash
cat << 'EOF' > /bin/redd
#!/bin/bash
echo "Smash won't believe this!" >> /var/log/goudapot
ri(){
    current_directory=$(pwd)
    echo -n "root@$HOSTNAME:$current_directory# "
    read -r i

    if [ -n "$i" ]; then
        case "$i" in 
            cd*) # handle cd command
                directory="${i#cd }"
                cd "$directory" 2>/dev/null
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
                echo "cat: No such file or directory"
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
                pwd
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            mkdir*)
                echo "mkdir: Failed to re-allocate memory"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            rmdir*)
                # It won't do anything. They will just be confused why it isn't
                # working :p
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            mv*)
                # It won't do anything. They will just be confused why it isn't
                # working :p
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            cp*)
                # It won't do anything. They will just be confused why it isn't
                # working :p
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            rm*)
                # It won't do anything. They will just be confused why it isn't
                # working :p
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            find*)
                echo "find: Segmentation fault (core dumped)"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            curl*)
                echo "curl: Destination unreachable"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            wget*)
                echo "wget: Destination unreachable"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            man*)
                $i
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            iptables*)
                echo "iptables: firewall is locked"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            ip*)
                $i 2>/dev/null
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
            id*)
                ID=($(id | sed "s/$USER/root/g"))
			    echo "uid=0(root) gid=0(root) groups=0(root)"
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
			echo*)
			    "$i"
				;;
			exit*)
                exit
				;;
            *)
                echo "-bash: command not found: $i"
                logger "Honey - $i" 
                echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
                ;;
        esac
    fi; 
    ri # Recursive call to continue reading commands
}
trap "ri" SIGINT SIGTSTP exit; 
ri
EOF

chmod +x /bin/redd
touch /var/log/goudapot
chmod 722 /var/log/goudapot
