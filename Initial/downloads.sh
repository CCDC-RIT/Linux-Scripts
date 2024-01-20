#!/bin/bash
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
    # TODO paranoia - what if some of these are already installed with bad/malicious configs? I don't think they get overwritten with the current settings...

    echo "Installing common packages..."
    # curl may be pre-installed in order to fetch this installer script in the first place...
    COMMON_PACKAGES="git curl vim tcpdump lynis net-tools tmux nmap fail2ban psad debsums clamav auditd vlock" #snoopy
    
    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apt install to install common packages."

        # Set debconf answer for unattended installation
        echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections
        # echo "snoopy <your-debconf-question> select Yes" | debconf-set-selections
    
        apt update
        apt install $COMMON_PACKAGES -y #-y for say yes to everything
    elif $REDHAT || $RHEL || $AMZ ; then
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS_NAME"
        echo "Using yum to install common packages."

        yum check-update
        yum install $COMMON_PACKAGES -y
    elif $ALPINE ; then 
        echo "Detected compatible OS: $OS_NAME"
        echo "Using apk to install common packages."

        apk update
        apk add $COMMON_PACKAGES #apk automatically has equivalent -y functionality
    elif $SLACK ; then 
        echo "Detected compatible OS: $OS_NAME"
        echo "Using slapt-get to install common packages."

        #slapt-get update #Not a thing for slapt-get
        slapt-get --install $COMMON_PACKAGES
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
    fi

    echo "Finished installing packages."
}

reinstall(){
    # Reinstall common essential packages
    echo "Reinstalling common essential packages..."

    COMMON_PACKAGES="passwd openssh-server" # TODO *pam* 
    
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

sources_list_reset() {
    # Migrated from reset_sources_list.sh by Guac0
    
    echo "Attempting to reset sources.list (or equivalent) to default value..."
    echo "OS detected: $OS_NAME"

    # Change depending on OS
    if $DEBIAN ; then
        # TODO restore sources.list.d?
        # TODO test

        mv /etc/apt/sources.list /etc/apt/sources.list.backup
        mv /etc/apt/sources.list.d /etc/apt/sources.list.d.backup
        mkdir /etc/apt/sources.list.d

        if $UBUNTU ; then 
            #Ubuntu
            # Get Ubuntu version codename
            ubuntu_version=$(lsb_release -sc)

            # Define sources.list entries based on Ubuntu version
            # TODO this includes the tabs, no functional value lost but its annoying
            sources_list_entries="
            deb http://us.archive.ubuntu.com/ubuntu/ $ubuntu_version main restricted
            # deb-src http://us.archive.ubuntu.com/ubuntu/ $ubuntu_version main restricted
            deb http://us.archive.ubuntu.com/ubuntu/ ${ubuntu_version}-security main restricted
            # deb-src http://us.archive.ubuntu.com/ubuntu/ ${ubuntu_version}-security main restricted
            "
        else
            #Debian
            # Get Debian version codename
            debian_version=$(lsb_release -sc)

            # Define sources.list entries based on Debian version
            sources_list_entries="
            deb http://ftp.us.debian.org/debian/ $debian_version main
            # deb-src http://ftp.us.debian.org/debian/ $debian_version main
            deb http://ftp.us.debian.org/debian/ ${debian_version}-security main
            # deb-src http://ftp.us.debian.org/debian/ ${debian_version}-security main
            "
        fi

        # Write new entries to sources.list
        # Why does chatgpt like to use tee here?
        echo "$sources_list_entries" | tee /etc/apt/sources.list > /dev/null

        # Add appropriate permissions to sources.list (should be done automatically by tee, but still)
        # TODO do all the OSes need this?
        chmod 644 /etc/apt/sources.list

        # Update package lists
        apt update

        echo "/etc/apt/sources.list and /etc/apt/sources.list.d have been reset!"
        echo "You can find their original files at the same file path, just renamed with the suffix '.backup'"

    elif $REDHAT || $RHEL; then
        # TODO test
        # TODO are these the minimal/necessary repos?
        # TODO does this os have a sources.list.d equivalent?

        # Get RHEL or CentOS version
        #rhel_version=$(rpm -E %{rhel})

        # Define repository entries based on RHEL or CentOS version
        : '
        repo_entries="
        [base]
        name=Red Hat Enterprise Linux \$releasever - Base
        baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/
        gpgcheck=1
        enabled=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

        [updates]
        name=Red Hat Enterprise Linux \$releasever - Updates
        baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/
        gpgcheck=1
        enabled=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

        [extras]
        name=Red Hat Enterprise Linux \$releasever - Extras
        baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/
        gpgcheck=1
        enabled=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
        "
        '

        # Backup existing yum configuration
        # mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/redhat.repo.backup

        # Apparently after deleting redhat.repo, you can run this command to rebuild the list
        # Dunno how reliable it is...
        #subscription-manager refresh

        # Write new entries to yum configuration
        # echo "$repo_entries" | tee /etc/yum.repos.d/redhat.repo > /dev/null

        # Clean metadata and refresh repositories
        # yum clean all
        # yum makecache

        # New method from here: https://access.redhat.com/discussions/5471181#comment-1929481

        # Backup existing yum configuration
        mv /etc/yum.repos.d/ /etc/yum.repos.d.backup

        yum clean all

        rm -r /var/cache/yum/*
        rm -r /etc/yum.repos.d/*

        subscription-manager remove --all
        subscription-manager unregister
        subscription-manager clean

        subscription-manager register
        subscription-manager refresh

        subscription-manager list --available
        # I dunno what a pool is so lets auto register
        #subscription-manager attach --pool=<Pool-ID>
        subscription-manager attach --auto

        yum update

        echo "/etc/yum.repos.d has been reset!"
        echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"
        
    elif $AMZ ; then 
        # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/add-repositories.html
        # TODO this is only for amazon linux 2!
        # TODO test
        # TODO are these the minimal/necessary repos?
        # TODO does this os have a sources.list.d equivalent?

        # Define repository entries for Amazon Linux
        repo_entries="
        [amzn-main]
        name=Amazon Linux 2 - amzn-main
        mirrorlist=http://amazonlinux.us-east-1.amazonaws.com/2/core/latest/x86_64/mirror.list
        enabled=1
        gpgcheck=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2

        [amzn-updates]
        name=Amazon Linux 2 - amzn-updates
        mirrorlist=http://amazonlinux.us-east-1.amazonaws.com/2/updates/latest/x86_64/mirror.list
        enabled=1
        gpgcheck=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2
        "

        # Backup existing yum configuration
        mv /etc/yum.repos.d/amzn2-core.repo /etc/yum.repos.d/amzn2-core.repo.backup

        # Write new entries to yum configuration
        echo "$repo_entries" | tee /etc/yum.repos.d/amzn2-core.repo > /dev/null

        # Clean metadata and refresh repositories
        yum clean all
        yum makecache

        echo "/etc/yum.repos.d/amzn2-core.repo has been reset!"
        echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

    elif $ALPINE ; then 
        # TODO test
        # TODO are these the minimal/necessary repos?
        # TODO does this os have a sources.list.d equivalent?

        # Define repository entries for Alpine Linux
        repo_entries="
        http://dl-cdn.alpinelinux.org/alpine/v3.14/main
        http://dl-cdn.alpinelinux.org/alpine/v3.14/community
        "

        # Backup existing apk configuration
        mv /etc/apk/repositories /etc/apk/repositories.backup

        # Write new entries to apk configuration
        echo "$repo_entries" | tee /etc/apk/repositories > /dev/null

        # Update the package index
        apk update

    elif $SLACK ; then 
        # TODO test
        # TODO are these the minimal/necessary repos?
        # TODO does this os have a sources.list.d equivalent?

        # Define repository entries for Slackware
        repo_entries="
        http://mirrors.slackware.com/slackware/slackware64-14.2/
        "

        # Backup existing slackpkg mirrors configuration
        mv /etc/slackpkg/mirrors /etc/slackpkg/mirrors.backup

        # Write new entries to slackpkg mirrors configuration
        echo "$repo_entries" | tee /etc/slackpkg/mirrors > /dev/null

        # Update the package list
        slackpkg update

        echo "/etc/slackpkg/mirrors has been reset!"
        echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

    elif $FEDORA ; then 
        # TODO test
        # TODO are these the minimal/necessary repos?
        # TODO does this os have a sources.list.d equivalent?

        # Get Fedora version
        fedora_version=$(rpm -E %fedora)

        # Define repository entries based on Fedora version
        repo_entries="
        [main]
        name=Fedora \$releasever - \$basearch
        metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-\$releasever&arch=\$basearch
        enabled=1
        gpgcheck=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch

        [updates]
        name=Fedora \$releasever - Updates
        metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f\$releasever&arch=\$basearch
        enabled=1
        gpgcheck=1
        gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
        "

        # Backup existing dnf configuration
        mv /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo.backup

        # Write new entries to dnf configuration
        echo "$repo_entries" | tee /etc/yum.repos.d/fedora.repo > /dev/null

        # Clean metadata and refresh repositories
        dnf clean all
        dnf makecache

        echo "/etc/yum.repos.d/fedora.repo has been reset!"
        echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

    fi

    echo "Sources.list reset finished!"
}

bash_rep() {
    # Install our own custom bashrc (bash config file) in case red team installed their own malicious one...

    echo "Replacing bashrc for new users and root..."
    mv /etc/skel/.bashrc /etc/skel/.bashrc.backup
    mv /root/.bashrc /root/.bashrc.backup
    cp -fr "Linux-Scripts/Initial/Hardening Script/configs/bashrc" /etc/skel/.bashrc
    cp -fr "Linux-Scripts/Initial/Hardening Script/configs/bashrc" /root/.bashrc
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

osquery_install() {
    echo "Installing Osquery"

    # Change package manager depending on OS
    if $DEBIAN || $UBUNTU ; then
        echo "Detected compatible OS: $OS_NAME"
        #uninstall old osquery (if present) first?
        dpkg -i Linux-Scripts/Binaries/osquery/osquery_5.11.0-1.linux_amd64.deb
        # fix missing dependencies
        apt-get install -f
        # Install OSQUERY config file and start service
        mv /etc/osquery/osquery.conf /etc/osquery/osquery.conf.backup
        cp -fr Linux-Scripts/Logging/osquery.conf /etc/osquery/osquery.conf
        osqueryctl start osqueryd

        # Do it a second time since last minute error!
        osqueryctl stop osqueryd
        mv /etc/osquery/osquery.conf /etc/osquery/osquery.conf.backup
        cp -fr Linux-Scripts/Logging/osquery.conf /etc/osquery/osquery.conf
        osqueryctl start osqueryd

        echo "Osquery installed from local binary repo of v5.11.0-1 and config file installed!"
    elif $REDHAT || $RHEL || $AMZ || $FEDORA ; then
        # REDHAT uses yum as native, AMZ uses yum or DNF with a yum alias depending on version
        # yum rundown: https://www.reddit.com/r/redhat/comments/837g3v/red_hat_update_commands/ 
        # https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf
        echo "Detected compatible OS: $OS_NAME"
        #uninstall old osquery (if present) first?
        dnf install Linux-Scripts/Binaries/osquery/osquery-5.11.0-1.linux.x86_64.rpm
        # Install OSQUERY config file and start service
        cp -fr Linux-Scripts/Logging/osquery.conf /etc/osquery/osquery.conf
        mv /etc/osquery/osquery.conf /etc/osquery/osquery.conf.backup
        osqueryctl start osqueryd

        echo "Osquery installed from local binary repo of v5.11.0-1 and config file installed!"
    else
        echo "Unsupported or unknown OS detected: $OS_NAME"
    fi
}

nginx_setup() {
    # If nginx appears to be installed, add our custom config file and restart it
    if [[ -d "/etc/nginx/" ]]; then
        # echo "Folder exists"
        echo "Nginx install detected, adding custom config file!"

        # Main config file needs to be manually edited so dont install it
        cp -fr Linux-Scripts/Proxy/nginx.conf /etc/nginx/nginx.conf.rit_ccdc_template

        # Make backups of these before importing new one
        mv /etc/nginx/conf.d/proxy.conf /etc/nginx/conf.d/proxy.conf.backup
        cp -fr Linux-Scripts/Proxy/proxy.conf /etc/nginx/conf.d/proxy.conf
        mv /etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf.backup
        cp -fr Linux-Scripts/Proxy/fastcgi.conf /etc/nginx/fastcgi.conf
        mv /etc/nginx/mime.conf /etc/nginx/mime.conf.backup
        cp -fr Linux-Scripts/Proxy/mime.conf /etc/nginx/mime.types
        mv /usr/share/nginx/run/nginx.pid /usr/share/nginx/run/nginx.pid.backup
        cp -fr Linux-Scripts/Proxy/nginx.pid /usr/share/nginx/run/nginx.pid
        mv /usr/share/nginx/logs/error.log /usr/share/nginx/logs/error.log.backup
        cp -fr Linux-Scripts/Proxy/error.log /usr/share/nginx/logs/error.log

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
# Then reset sources list (for security, but also might break things), reinstall common packages, then fetch all scripts, then everything that depends on repo (installing configs)
# If you're running this script offline, comment out os detect, common pack, and fetch scripts (you will need Linux-Scripts repo folder in the same directory as this script!)
apt install curl -y
setup_os_detection
#sources_list_reset
reinstall
common_pack
fetch_all_scripts
setup_honeypot
bash_rep
install_wazuh
nginx_setup
osquery_install

echo "Downloads script complete!"

# Delete after running. If you need this script again, it'll be in the newly-downloaded script repository under the blue user.
# https://stackoverflow.com/questions/8981164/self-deleting-shell-script
# When your script is finished, exit with a call to the function, "finish":
trap finish EXIT