#######################################################
# Completes the 'setup logging' part of the Linux Quran
# Reorganized by Guac0
#######################################################

#!/bin/bash

# Import the OS variables
# Needs os_detection.sh to run first
PATH_TO_OS_RESULTS_FILE="../Initial/os.txt" #default path is set to use os.txt as created by Linux-Scripts/Initial/os_detection.sh
if [ -f $PATH_TO_OS_RESULTS_FILE ] ; then
    source $PATH_TO_OS_RESULTS_FILE
else
    echo "Operating System information file (as produced by os_detection.sh) not found! Exiting..."
    exit
fi

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi


echo "Completes the 'Setup Logging' section of the linux quran"

get_install_options() {
    read -p "Enter IPv4 address of Wazuh manager to connect to: " WAZUH_ADDRESS < /dev/tty
    read -p "Enter port number of Wazuh manager to connect to (Recommend 1514): " WAZUH_PORT < /dev/tty
    read -p -s "Enter password for Wazuh manager registration: " WAZUH_PASSWORD < /dev/tty
    read -p "Enter group name to enroll with at the Wazuh manager: " WAZUH_GROUP < /dev/tty
}

wazuh_setup() {
    # Do Wazuh, by Guac.0
    if $DEBIAN || $UBUNTU ; then
        # uses apt and systemd
        echo "Detected compatible OS: $OS_NAME"

        # Enable and start the Wazuh agent service
        systemctl daemon-reload
        systemctl enable wazuh-agent
        systemctl start wazuh-agent

        # Install wazuh config file
        VERSION=lsb_release -si
        #curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/agent_linux.conf > /var/ossec/etc/ossec.conf
        curl agent_linux.conf > /var/ossec/etc/ossec.conf
        sed -i 's/[MANAGER_IP]/${WAZUH_ADDRESS}/g' /var/ossec/etc/ossec.conf
        sed -i 's/1514/${WAZUH_PORT}/g' /var/ossec/etc/ossec.conf
        sed -i 's/[OS AND VERSION]/${VERSION}/g' /var/ossec/etc/ossec.conf #TODO bad...
        sed -i 's/<groups>default</groups>/<groups>${WAZUH_GROUP}</groups>/g' /var/ossec/etc/ossec.conf
        # sed -i 's/<authorization_pass_path>etc/authd.pass</authorization_pass_path>/<authorization_pass_path>new-text</authorization_pass_path>/g' /var/ossec/etc/ossec.conf #TODO password

        # Check if there are running Docker containers
        if docker ps -q 2>/dev/null; then
            # echo "There are running Docker containers."
            sed -i 's/dockerchangeme/no/g' /var/ossec/etc/ossec.conf
        else
            # echo "There are no running Docker containers."
            sed -i 's/dockerchangeme/yes/g' /var/ossec/etc/ossec.conf
        fi
    elif $REDHAT || $RHEL || $AMZ ; then
        # uses yum and systemd
        echo "Detected compatible OS: $OS_NAME"

        # Enable and start the Wazuh agent service 
        systemctl daemon-reload
        systemctl enable wazuh-agent
        systemctl start wazuh-agent

        # Install wazuh config file
        VERSION=lsb_release -si
        #curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/agent_linux.conf > /var/ossec/etc/ossec.conf
        curl agent_linux.conf > /var/ossec/etc/ossec.conf
        sed -i 's/[MANAGER_IP]/${WAZUH_ADDRESS}/g' /var/ossec/etc/ossec.conf
        sed -i 's/1514/${WAZUH_PORT}/g' /var/ossec/etc/ossec.conf
        sed -i 's/[OS AND VERSION]/${VERSION}/g' /var/ossec/etc/ossec.conf #TODO bad...
        sed -i 's/<groups>default</groups>/<groups>${WAZUH_GROUP}</groups>/g' /var/ossec/etc/ossec.conf
        # sed -i 's/<authorization_pass_path>etc/authd.pass</authorization_pass_path>/<authorization_pass_path>new-text</authorization_pass_path>/g' /var/ossec/etc/ossec.conf #TODO password

        # Check if there are running Docker containers
        if docker ps -q 2>/dev/null; then
            # echo "There are running Docker containers."
            sed -i 's/dockerchangeme/no/g' /var/ossec/etc/ossec.conf
        else
            # echo "There are no running Docker containers."
            sed -i 's/dockerchangeme/yes/g' /var/ossec/etc/ossec.conf
        fi
    elif $ALPINE ; then 
        # uses apk and none
        echo "Detected partially compatible OS: $OS_NAME"
        #echo "Using apk to install Wazuh Agent."
        #echo "See below warning(s) for more details."

        #todo variables
        echo "WARNING: Installer for $OS_NAME cannot automatically add configuration details like manager IP address."
        echo "You must set these configuration details manually."
        #export WAZUH_MANAGER="10.0.0.2" && sed -i "s|MANAGER_IP|$WAZUH_MANAGER|g" /var/ossec/etc/ossec.conf

        # Start agent manually
        /var/ossec/bin/wazuh-control start
    else
        echo "Unsupported or unknown OS detected: $OS_NAME"
        echo "Please proceed to install and set up Wazuh Agent manually."
        exit
    fi

    # Filepath *should* be the same in all OSes according to docs
    # https://documentation.wazuh.com/current/user-manual/reference/statistics-files/wazuh-agentd-state.html
    filepath=/var/ossec/var/run/wazuh-agentd.state
    if [ -e "$filepath" ]; then
        # echo "File exists."
        if grep -q "status='connected'" $filepath; then
            # echo "The file contains 'status=connected'."
            echo "Wazuh client agent has connected to the manager successfully!"
        else
            # echo "The file does not contain 'status=connected'."
            echo "Wazuh client agent has not connected to the manager successfully, see $filepath for details!"
        fi
    else
        echo "Error: $filepath does not exist, wazuh client agent connection state cannot be automatically determined by this script!"
        # Your code here if the file does not exist
    fi

    #Extra config option to enable remote commands for centralized config by jznn
    echo "sca.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf
}

# Snoopy
# if [[ $distro == "Ubuntu" ]]; then
if $DEBIAN || $UBUNTU ; then #probably fine to also do if debian
    echo "Ubuntu/Debian Setup"

    echo "Installing Snoopy..."
    apt-get install snoopy -y
    /usr/sbin/snoopy-enable

    echo "Installing Filebeat..."
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.5.2-amd64.deb
    dpkg -i filebeat-7.5.2-amd64.deb
    filebeat modules enable system
    filebeat setup
    systemctl start filebeat
    echo "Some changes you might want to make to the /etc/filebeat/filebeat.yml
file.

output.elasticsearch:
    hosts: [\"172.16.9.X:9200\"]
setup.kibana:
    hosts: \"172.16.9.X:5601\"
"
    
    echo "Insatlling/Setting up auditd..."
    apt-get install auditd
    auditctl -D
    echo "
auditctl -D
auditctl -a exit,always -F arch=b64 -F euid=0 -S execve -k ROOT_EXEC
auditctl -a exit,always -F arch=b32 -F euid=0 -S execve -k ROOT_EXEC
auditctl -a always,exit -F arch=b64 -S socket -F al=3 -k RAWSOCK
auditctl -a always,exit -F arch=b32 -S socket -F al=3 -k RAWSOCK
" | tee -a /opt/rules.sh > /dev/null

    bash /opt/rules.sh
    auditctl -e 2

    echo "Enabling Bash logging..."
    export PROMPT_COMMAND='RT=$?; echo "$(date) $(whoami) <$SSH_CLIENT> [$$]: $(history 1) [$RT]" >> /var/log/.tmp-ICE'
    chmod 666 /var/log/.tmp-ICE
fi

# Don't have a working centos vm setup so not completing those steps right now.

###############
#### MAIN #####
###############

wazuh_setup
