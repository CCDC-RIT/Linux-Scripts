# DEPRECATED, was merged into setup_logging.sh and downloads.sh

#####################################################
# Installs the Wazuh agent service on a *unix machine
# Compatible with Debian (Tested), Ubuntu (Tested), RHEL, Amazon Linux, (partially) Alpine
# Dependencies: valid os detection file (os_detection.sh)
# Created by Guac0
#####################################################
# https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-linux.html

# Issues:
# syntax for yum install with EOF
# Is it possible to print wazuh connection status to the user? Rn user has no way to see if wazuh manager connection was established

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

get_install_options() {
    read -p "Enter IPv4 address of Wazuh manager to connect to: " WAZUH_ADDRESS < /dev/tty
    read -p "Enter port number of Wazuh manager to connect to (Recommend 1514): " WAZUH_PORT < /dev/tty
    read -p -s "Enter password for Wazuh manager registration: " WAZUH_PASSWORD < /dev/tty
    read -p "Enter group name to enroll with at the Wazuh manager: " WAZUH_GROUP < /dev/tty
}

# Change package manager depending on OS
if $DEBIAN || $UBUNTU ; then
    # uses apt and systemd
    echo "Detected compatible OS: $OS_NAME"
    echo "Using apt and systemd to install Wazuh Agent."

    # Uninstall potential old Wazuh
    # apt-get remove wazuh-agent
    # apt-get remove --purge wazuh-agent # Removes config files
    # systemctl disable wazuh-agent
    # systemctl daemon-reload

    # Add the Wazuh repo
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
    apt-get update
    
    # Install Wazuh (specifically, 4.7.1 for some reason)
    # TODO other install variables?
    get_install_options
    WAZUH_MANAGER="${WAZUH_ADDRESS}" WAZUH_MANAGER="${WAZUH_PORT}" \
     WAZUH_REGISTRATION_PASSWORD="${WAZUH_PASSWORD}" WAZUH_AGENT_GROUP="${WAZUH_GROUP}" \
      apt-get install wazuh-agent

    # Enable and start the Wazuh agent service
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent

    # Install wazuh config file
    VERSION=lsb_release -si
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/agent_linux.conf > /var/ossec/etc/ossec.conf
    sed -i 's/[MANAGER_IP]/${WAZUH_ADDRESS}/g' /var/ossec/etc/ossec.conf
    sed -i 's/1514/${WAZUH_PORT}/g' /var/ossec/etc/ossec.conf
    sed -i 's/[OS AND VERSION]/${VERSION}/g' /var/ossec/etc/ossec.conf
    sed -i 's/<groups>default</groups>/<groups>${WAZUH_GROUP}</groups>/g' /var/ossec/etc/ossec.conf
    # sed -i 's/<authorization_pass_path>etc/authd.pass</authorization_pass_path>/<authorization_pass_path>new-text</authorization_pass_path>/g' /var/ossec/etc/ossec.conf #password

    # After install, remove Wazuh repo to prevent potential updates and getting out of sync from the manager
    sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
    apt-get update
    # Alternatively, you can set the package state to hold. This action stops updates but you can still upgrade it manually using apt-get install.
    # echo "wazuh-agent hold" | dpkg --set-selections

elif $REDHAT || $RHEL || $AMZ ; then
    # uses yum and systemd
    echo "Detected compatible OS: $OS_NAME"
    echo "Using yum and systemd to install Wazuh Agent."

    # Uninstall potential old Wazuh
    #yum remove wazuh-agent
    #systemctl disable wazuh-agent
    #systemctl daemon-reload

    # Add the Wazuh repo
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    # TODO not sure if this syntax is right, can't test it rn
    # It's the same as it says on the website
    #cat <<-EOF
    #    [wazuh]
    #    gpgcheck=1
    #    gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
    #    enabled=1
    #    name=EL-\$releasever - Wazuh
    #    baseurl=https://packages.wazuh.com/4.x/yum/
    #    protect=1
    #EOF > /etc/yum.repos.d/wazuh.repo

    # Install Wazuh
    # TODO other install variables?
    WAZUH_MANAGER="${WAZUH_ADDRESS}" WAZUH_MANAGER="${WAZUH_PORT}" \
     WAZUH_REGISTRATION_PASSWORD="${WAZUH_PASSWORD}" WAZUH_AGENT_GROUP="${WAZUH_GROUP}" \
      yum install wazuh-agent-4.7.1

    # Enable and start the Wazuh agent service 
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent

    # Install wazuh config file
    VERSION=lsb_release -si
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/agent_linux.conf > /var/ossec/etc/ossec.conf
    sed -i 's/[MANAGER_IP]/${WAZUH_ADDRESS}/g' /var/ossec/etc/ossec.conf
    sed -i 's/1514/${WAZUH_PORT}/g' /var/ossec/etc/ossec.conf
    sed -i 's/[OS AND VERSION]/${VERSION}/g' /var/ossec/etc/ossec.conf
    sed -i 's/<groups>default</groups>/<groups>${WAZUH_GROUP}</groups>/g' /var/ossec/etc/ossec.conf
    # sed -i 's/<authorization_pass_path>etc/authd.pass</authorization_pass_path>/<authorization_pass_path>new-text</authorization_pass_path>/g' /var/ossec/etc/ossec.conf #password

    # After install, remove Wazuh repo to prevent potential updates and getting out of sync from the manager
    sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo

elif $ALPINE ; then 
    # uses apk and none
    echo "Detected partially compatible OS: $OS_NAME"
    echo "Using apk to install Wazuh Agent."
    echo "See below warning(s) for more details."

    # Uninstall potential old Wazuh
    #apk del wazuh-agent

    # Add the Wazuh repo
    wget -O /etc/apk/keys/alpine-devel@wazuh.com-633d7457.rsa.pub https://packages.wazuh.com/key/alpine-devel%40wazuh.com-633d7457.rsa.pub
    echo "https://packages.wazuh.com/4.x/alpine/v3.12/main" >> /etc/apk/repositories
    apk update

    # Install Wazuh
    apk add wazuh-agent
    
    #todo variables
    echo "WARNING: Installer for $OS_NAME cannot automatically add configuration details like manager IP address."
    echo "You must set these configuration details manually."
    #export WAZUH_MANAGER="10.0.0.2" && sed -i "s|MANAGER_IP|$WAZUH_MANAGER|g" /var/ossec/etc/ossec.conf

    # Start agent manually
    /var/ossec/bin/wazuh-control start

    # After install, remove Wazuh repo to prevent potential updates and getting out of sync from the manager
    sed -i "s|^https://packages.wazuh.com|#https://packages.wazuh.com|g" /etc/apk/repositories

elif $SLACK ; then
    # slapt-get is not supported
    # uses systemv
    echo "Detected incompatible OS: $OS_NAME"
    echo "Slapt-get is not natively supported by Wazuh, please manually install Wazuh using a different package manager."
    exit
else
    echo "Unsupported or unknown OS detected: $OS_NAME"
    echo "Please proceed to install Wazuh Agent manually."
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

echo "sca.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf