#!/bin/bash
# red team backdoor
cat << 'EOF' > /bin/redd
#!/bin/bash
echo "Caught one boys!" >> /var/log/goudapot
ri(){
    echo -n "root@$HOSTNAME:~# "
    read i; if [ -n "$i" ]; then
      echo "-bash: $i: command not found"
      echo "$(date +"%A %r") -- $i" >> /var/log/goudapot
    fi; ri
}
trap "ri" SIGINT SIGTSTP exit; ri
EOF

chmod +x /bin/redd
touch /var/log/goudapot
chmod 722 /var/log/goudapot
