#!/bin/bash

#5 min plan script
if  [ "$EUID" -ne 0 ]; then 
    echo "User is not root. Skill issue."
    exit 
fi

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

# Sed sshd_config

sed_ssh() {
    sed -i.bak 's/.*\(#\)\?Port.*/Port 22/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?Protocol.*/Protocol 2/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?UsePrivilegeSeperation.*/UsePrivilegeSeperation yes/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?KeyRegenerationInterval.*/KeyRegenerationInterval 3600/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?ServerKeyBits.*/ServerKeyBits 1024/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?SyslogFacility.*/SyslogFacility AUTH/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?LogLevel.*/LogLevel VERBOSE/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?LoginGraceTime.*/LoginGraceTime 120/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?StrictModes.*/StrictModes yes/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?MaxAuthTries.*/MaxAuthTries 1/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?MaxSessions.*/MaxSessions 5/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?RSAAuthentication.*/RSAAuthentication no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?PubkeyAuthentication.*/PubkeyAuthentication no/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?IgnoreRhosts.*/IgnoreRhosts yes/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?RhostsRSAAuthentication.*/RhostsRSAAuthentication no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?HostbasedAuthentication.*/HostbasedAuthentication no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?IgnoreUserKnownHosts.*/IgnoreUserKnownHosts yes/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?X11DisplayOffset.*/X11DisplayOffset 10/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?PrintMotd.*/PrintMotd no/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?PrintLastLog.*/PrintLastLog yes/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?TCPKeepAlive.*/TCPKeepAlive yes/g' /etc/ssh/sshd_config
    sed -i.bak 's/.*\(#\)\?UseLogin.*/UseLogin yes/g' /etc/ssh/sshd_config

    sed -i.bak '/Subsystem sftp/d' /etc/ssh/sshd_config

    sed -i.bak 's/.*\(#\)\?UsePAM.*/UsePAM no/g' /etc/ssh/sshd_config

    echo "Edited sshd_config"
}

reset_environment() {
    echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games\"" > /etc/environment
}

check_ssh_keys() {
    echo "\n Checking for ssh keys..."
    s="sudo"
    $s cat /root/ssh/sshd_config | grep -i AuthorizedKeysFile
    $s head -n 20 /home/*/.ssh/authorized_keys*
    $s head -n 20 /root/.ssh/authorized_keys*
}

find_auto_runs() {
    echo "\n Checking for autoruns..."
    s="sudo"
    $s cat /etc/crontab | grep -Ev '#|PATH|SHELL'
    $s cat /etc/cron.d/* | grep -Ev '#|PATH|SHELL'
    $s find /var/spool/cron/crontabs/ -printf '%p\n' -exec cat {} \;
    $s systemctl list-timers
}


# main

backups
reset_environment
sed_ssh
check_ssh_keys

# add more here

