# Created by Guac0 using code from vipersniper0501 for CCDC 2024

# Objective:
# Have a central downloader script that'll fetch all the other scripts and etc.
# Also install some common packages and shell stuff

# Usage:
# Note - Tested on Debian 12 and Ubuntu 22.04.03
# 1. Install curl via "sudo apt install curl"
# 2. Obtain this script via "curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/downloads.sh > downloader.sh"
# 3. Run it via "sudo sh downloads" or your equivalent bash execution method
#      If you get an error like "useradd command not found", start a superuser session with "su -l"
# 4. If you get configuration popups, the defaults should likely work fine.
# 5. The script will then automatically delete itself. The installed scripts are located in /home/blue/Linux-Scripts

# Tasks/Questions:
# Where do we download these files to? - blue user home directory in scripts folder
# Migrate downloading and installing honeypot - done
# Download and install packages - done (well, the original ones given to me at least)
# General move from 5MinPlan.sh to this - done
# Add inter-OS interdependency - done

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi

setup_os_detection() {
    # Import and run the os detector script in the current directory
    # Run this first before stuff that needs to know the OS, like common_pack()

    echo "Importing OS detection method..."
    curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Initial/os_detection.sh > os_detection.sh
    bash os_detection.sh

    # Import results
    PATH_TO_OS_RESULTS_FILE="./os.txt"
    if [ -f $PATH_TO_OS_RESULTS_FILE ] ; then
        source $PATH_TO_OS_RESULTS_FILE
    else
        echo "Operating System information file (as produced by os_detection.sh) not found! Exiting..."
        exit
    fi

    echo "OS detection completed."
}

unsupported_os() {
    # Currently unused
    echo "The downloader script has successfully identified the OS as $OS_NAME, but this OS is not supported."
    echo "The downloader script will now exit."
    exit
}

common_pack() {
    # Install common packages
    #
    # TODO Needs to be able to fix sources.list (red team can point to their own malicious sources)
    # TODO paranoia - what if some of these are already installed with bad/malicious configs? I don't think they get overwritten with the current settings...

    echo "Installing common packages..."
    # curl may be pre-installed in order to fetch this installer script in the first place...
    COMMON_PACKAGES="git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav snoopy auditd"
    
    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apt install to install common packages."

        apt update
        apt install $COMMON_PACKAGES -y #-y for say yes to everything

        # OSQUERY custom stuff because yay custom repo
        # https://osquery.io/downloads/official/5.11.0
        # fix for install error: https://github.com/osquery/osquery/issues/8105 
        curl -fsSL  https://pkg.osquery.io/deb/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/osquery.gpg
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/osquery.gpg] https://pkg.osquery.io/deb deb main" | tee /etc/apt/sources.list.d/osquery.list > /dev/null
        apt update
        apt install osquery

        # Install OSQUERY config file
        curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/osquery.conf > /etc/osquery/osquery.conf
    elif $REDHAT || $RHEL || $AMZ ; then
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS_NAME"
        echo "Using yum to install common packages."

        yum check-update
        yum install $COMMON_PACKAGES -y

        # OSQUERY custom stuff because yay custom repo
        # https://osquery.io/downloads/official/5.11.0
        curl -L https://pkg.osquery.io/rpm/GPG | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
        yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
        yum-config-manager --enable osquery-s3-rpm-repo
        yum install osquery

        # Install OSQUERY config file
        curl https://raw.githubusercontent.com/CCDC-RIT/Linux-Scripts/main/Logging/osquery.conf > /etc/osquery/osquery.conf
    elif $ALPINE ; then 
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apk to install common packages."

        apk update
        apk add $COMMON_PACKAGES #apk automatically has equivalent -y functionality
    
        # TODO osquery
    elif $SLACK ; then 
        echo "Detected compatible OS: $OS_NAME"
        echo "Using slapt-get to install common packages."

        #slapt-get update #Not a thing for slapt-get
        slapt-get --install $COMMON_PACKAGES

        #TODO osquery
    else
        echo "Unsupported or unknown OS detected: $OS_NAME"
        #read -p "Please enter the command to update the package manager's list of available packages (such as 'apt update'): " PKG_UPDATE < /dev/tty
        #read -p "If applicable, add any arguments you wish to add to the update command: " PKG_UPDATE_ARGS < /dev/tty
        #read -p "Please enter the command to install a new package (such as 'apt install'): " PKG_INSTALL < /dev/tty
        #read -p "If applicable, add any arguments you wish to add to the install command (such as '-y'): " PKG_INSTALL_ARGS < /dev/tty
        #Only execute the commands if they're not empty
        #if ! [ -z "$PKG_UPDATE" ];
        #then
            #not empty
        #    if ! [ -z "$PKG_UPDATE_ARGS" ];
        #    then
                #not empty
        #        $PKG_UPDATE $PKG_UPDATE_ARGS
        #    else
        #        $PKG_UPDATE
        #    fi
        #fi
        #if ! [ -z "$PKG_INSTALL" ];
        #then
            #not empty
        #    if ! [ -z "$PKG_INSTALL_ARGS" ];
        #    then
        #        #not empty
        #        $PKG_INSTALL $COMMON_PACKAGES $PKG_INSTALL_ARGS
        #    else
        #        $PKG_INSTALL $COMMON_PACKAGE
        #    fi
        # fi

        #TODO osquery
    fi

    echo "Finished installing packages."
}

reinstall(){
    # Reinstall common essential packages
    echo "Reinstalling common essential packages..."

    COMMON_PACKAGES="passwd *pam* openssh-server"
    
    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apt install to reinstall common packages."

        apt update
        apt install --reinstall $COMMON_PACKAGES -y #-y for say yes to everything
    elif $REDHAT || $RHEL || $AMZ ; then
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS_NAME"
        echo "Using yum to reinstall common packages."

        yum check-update
        yum reinstall $COMMON_PACKAGES -y
    elif $ALPINE ; then 
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apk to reinstall common packages."

        apk update
        apk fix -r $COMMON_PACKAGES #apk reinstalling
    else
        echo "Unsupported or unknown OS detected: $OS_NAME"
    fi

    echo "Finished reinstalling packages."
}

bash_rep() {
    # Install our own custom bashrc (bash config file) in case red team installed their own malicious one...

    echo "Replacing bashrc for new users and root..."
    cp "Linux-Scripts/Initial/bashrc/Hardening Script/configs/bashrc" > /etc/skel/.bashrc
    cp "Linux-Scripts/Initial/bashrc/Hardening Script/configs/bashrc" > /root/.bashrc
    echo "Replaced .bashrc"
}

setup_honeypot() {
    # Set up our own shell replacement for all users that just traps them into a honeypot.
    # All users should also have a secure password and etc for security...
    # If a user needs to use shell for legit reasons, you need to manually reset their shell.

    echo "Downloading honeypot..."
    # Download and run the setup script
    bash Linux-Scripts/Initial/gouda.sh

    # Don't actually install it into /etc/passwd as user hardening script will do that
    #sed -i.bak 's|/bin/sh|/bin/redd|g' /etc/passwd
    #sed -i.bak 's|/bin/bash|/bin/redd|g' /etc/passwd
    echo "Honeypot prepped and placed in /bin/redd"
}

fetch_all_scripts() {
    # ~~Just download all the scripts to the home folder of the blue team users~~ nvm now due to migration to users.sh
    # ~~Call this AFTER blue user is set up! (setup_honeypot)~~ nvm now due to migration to users.sh
    # If we didn't make an admin user, just download to the current directory

    #if ! [ -z "$NAME" ];
    #then
        # If we did make an admin user, then toss the scripts into their home and make them all editable
    #    git clone https://github.com/CCDC-RIT/Linux-Scripts/ /home/$NAME/Linux-Scripts
    #    find /home/$NAME/Linux-Scripts -type f -iname "*.sh" -exec chmod +x {} \;
    #    echo "Scripts have been downloaded to /home/$NAME/Linux-Scripts"
    #else

    # If we didn't make an admin user, then toss the scripts into the current directory and make them all editable
    git clone https://github.com/CCDC-RIT/Linux-Scripts/
    find ./ -type f -iname "*.sh" -exec chmod +x {} \;
    echo "Scripts have been downloaded to ./Linux-Scripts"

    #fi
}

install_wazuh() {
    echo "Installing Wazuh"

    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS_NAME"
        # Uninstall potential old Wazuh
        # apt-get remove wazuh-agent
        # apt-get remove --purge wazuh-agent # Removes config files
        # systemctl disable wazuh-agent
        # systemctl daemon-reload
        if $DEBIAN ; then
            dpkg -i Linux-Scripts/Binaries/Wazuh/wazuh-agent_4.7.2-1_amd64_debian.deb
        else
            # Ubuntu!
            dpkg -i Linux-Scripts/Binaries/Wazuh/wazuh-agent_4.7.2-1_amd64_ubuntu.deb
        fi
        # fix missing dependencies
        apt-get install -f
        # We'll handle setup in logging script...
        echo "Wazuh installed from local binary repo of v4.7.2-1! Configuration not completed, this will be done in the logging setup script."
    elif $REDHAT || $RHEL || $AMZ || $FEDORA ; then
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS_NAME"
        # Uninstall potential old Wazuh
        #yum remove wazuh-agent
        #systemctl disable wazuh-agent
        #systemctl daemon-reload
        if $REDHAT || $RHEL ; then 
            dnf install Linux-Scripts/Binaries/Wazuh/wazuh-agent-4.7.2-1.x86_64_rhel.rpm
        elif $AMZ ; then
            dnf install Linux-Scripts/Binaries/Wazuh/wazuh-agent-4.7.2-1.x86_64_amazon.rpm
        elif $FEDORA ; then
            dnf install Linux-Scripts/Binaries/Wazuh/wazuh-agent-4.7.2-1.x86_64_fedora.rpm
        fi
        # We'll handle setup in logging script...
        echo "Wazuh installed from local binary repo of v4.7.2-1! Configuration not completed, this will be done in the logging setup script."
    #elif $ALPINE ; then 
        #no alpine for now because chatgpt thinks im talking about android and we're not using it anyways
    #    echo "Detected compatible OS: $OS_NAME"
        # Uninstall potential old Wazuh
        # apk del wazuh-agent
    #
        # We'll handle setup in logging script...
    #    echo "Wazuh installed from local binary repo of v4.7.2-1! Configuration not completed, this will be done in the logging setup script."
    else
        echo "Unsupported or unknown OS detected: $OS_NAME"
    fi
}

nginx_setup() {
    # If nginx appears to be installed, add our custom config file and restart it
    if [[ -d "/etc/nginx/" ]]; then
        # echo "Folder exists"
        echo "Nginx install detected, adding custom config file!"

        mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
        cp Linux-Scripts/Proxy/nginx.conf /etc/nginx/nginx.conf

        # Restart service
        if $DEBIAN || $UBUNTU || $REDHAT || $RHEL || $AMZ || $FEDORA; then
            systemctl restart nginx
            # There's some confusion as to use systemctl vs service...
        elif $ALPINE ; then 
            rc-service nginx restart
        else
            # Unknown OS. You can choose whether to just exit/do nothing with an error message, or to implement a custom fallback behavior.
            echo "Unsupported or unknown OS detected for restarting nginx service automaticly: $OS_NAME"
        fi

        echo "Nginx config file installed, previous config file can be found at /etc/nginx/nginx.conf.backup!"
    else
        # echo "Folder does not exist"
        echo "Nginx appears not to be installed (or not installed in the default location), nginx setup cancelled!"
    fi
}

finish() {
    # At end, delete this file as there's no reason to keep it around
    # Shred is probably overkill
    # currentscript="$0"
    echo "Securely shredding '$0' and associated os_detection.sh and os.txt"
    shred -u $0 #this errors with quotes, however, if we don't have quotes then it *might* stop at the first space in the file path and delete that new path
                    # However, our usage case doesn't involve a full path, and it'll work fine when executed from the same directory, or in a full path without a space
    # Delete OS stuff too because theyre gonna be in a random place (where downloader.sh was downloaded and executed) instead of with the rest of the scripts. Some other setup script (ansible?) will re-execute OS detection in its proper place (downloaded git repo folder)
    shred -u "./os_detection.sh"
    # make os file writable again for deletion
    chattr -i os.txt
    chmod u+w os.txt
    shred -u "./os.txt"
}



#################################################
# Main code
#################################################

# Keep in mind chicken and the egg!
# First we need OS detection (so that we can use right pkg manager)
# Then common packages, then fetch all scripts, then everything that depends on repo (installing configs)
# If you're running this script offline, comment out os detect, common pack, and fetch scripts (you will need Linux-Scripts repo folder in the same directory as this script!)
setup_os_detection

reinstall
common_pack
fetch_all_scripts
setup_honeypot
bash_rep
install_wazuh
nginx_setup

echo "Downloads script complete!"

# Delete after running. If you need this script again, it'll be in the newly-downloaded script repository under the blue user.
# https://stackoverflow.com/questions/8981164/self-deleting-shell-script
# When your script is finished, exit with a call to the function, "finish":
trap finish EXIT