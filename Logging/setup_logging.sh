#!/bin/bash

echo "Completes the 'Setup Logging' section of the linux quran"

distro=$(lsb_release -i | cut -f 2-)

# Snoopy
if [[ $distro == "Ubuntu" ]]; then
    echo "Ubuntu Setup"

    echo "Installing Snoopy..."
    sudo apt-get install snoopy -y
    sudo /usr/sbin/snoopy-enable

    echo "Installing Filebeat..."
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.5.2-amd64.deb
    sudo dpkg -i filebeat-7.5.2-amd64.deb
    sudo filebeat modules enable system
    sudo filebeat setup
    sudo systemctl start filebeat
    echo "Some changes you might want to make to the /etc/filebeat/filebeat.yml
file.

output.elasticsearch:
    hosts: [\"172.16.9.X:9200\"]
setup.kibana:
    hosts: \"172.16.9.X:5601\"
"
    
    echo "Insatlling/Setting up auditd..."
    sudo apt-get install auditd
    sudo auditctl -D
    echo "
auditctl -D
auditctl -a exit,always -F arch=b64 -F euid=0 -S execve -k ROOT_EXEC
auditctl -a exit,always -F arch=b32 -F euid=0 -S execve -k ROOT_EXEC
auditctl -a always,exit -F arch=b64 -S socket -F al=3 -k RAWSOCK
auditctl -a always,exit -F arch=b32 -S socket -F al=3 -k RAWSOCK
" | sudo tee -a /opt/rules.sh > /dev/null

    sudo bash /opt/rules.sh
    sudo auditctl -e 2

    echo "Enabling Bash logging..."
    export PROMPT_COMMAND='RT=$?; echo "$(date) $(whoami) <$SSH_CLIENT> [$$]: $(history 1) [$RT]" >> /var/log/.tmp-ICE'
    chmod 666 /var/log/.tmp-ICE
fi

# Don't have a working centos vm setup so not completing those steps right now.
