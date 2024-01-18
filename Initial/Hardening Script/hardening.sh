#!/bin/bash

# by: Justin Huang (jznn)
# Prerequisites: run as root, and users.txt file exists in same dir, can be created using getUsers.sh in setup folder

# check if /etc/redhat-release file exists, indicating a RHEL-based system
if [ -e /etc/redhat-release ]; then
    os_type="RHEL"
# check if /etc/debian_version file exists, indicating a debian-based system
elif [ -e /etc/debian_version ]; then
    os_type="Debian"

# verify that script is being run with root privileges
if  [ "$EUID" -ne 0 ]; then 
    echo "User is not root. Skill issue."
    exit 
fi

if [ ! -f "./users.txt" ]; then
    echo "Necessary text files for users is not present. Shutting down script."
    exit 1
fi

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
    echo "Edited sshd_config, ssh service restarting"
    systemctl restart ssh
}

fix_corrupt(){
    if [ "$os_type" = "RHEL" ]; then
        echo "fixing corrupt packages"
        rpm -qf $(rpm -Va 2>&1 | grep -vE '^$|prelink:' | sed 's|.* /|/|') | sort -u
    fi

    if [ "$os_type" = "Debian" ]; then
        echo "fixing corrupt packages"
        apt-fast install --reinstall $(dpkg -S $(debsums -c) | cut -d : -f 1 | sort -u) -y
        echo "fixing files with missing files"
        xargs -rd '\n' -a <(sudo debsums -c 2>&1 | cut -d " " -f 4 | sort -u | xargs -rd '\n' -- dpkg -S | cut -d : -f 1 | sort -u) -- sudo apt-get install -f --reinstall --
    fi
}

reset_environment() {
    echo "\n Resetting PATH variable"
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

kernel(){
    echo "\n Resetting sysctl.conf file"
    cat configs/sysctl.conf > /etc/sysctl.conf
    echo 0 > /proc/sys/kernel/unprivileged_userns_clone
}

aliases(){
    echo "\n Resetting user bashrc files and profile file" 
	for user in $(cat users.txt); do
        	cat configs/bashrc > /home/$user/.bashrc;
	done;
	cat configs/bashrc > /root/.bashrc
	cat configs/profile > /etc/profile
}

configCmds(){
	cat configs/adduser.conf > /etc/adduser.conf
	cat configs/deluser.conf > /etc/deluser.conf
}

noIpv6(){
    echo "/n Removing IPv6..."
    interfaces=$(ifconfig | grep "flags" | awk '{print $1}' | tr -d ':')
    if [ os_type == "Debian" ]; then
        echo "removing IPv6 from sysctl"
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p
        echo "removing IPv6 on each interface"
        in="/etc/networks/interfaces"
        if [ -e "$in" ]; then
            echo -e "using $in"
            for interface in $interfaces; do
                echo "iface $interface inet6 manual" >> "$in"
            done
            echo "Networking interface configuration applied"
        fi
        np="/etc/netplan/01-netcfg.yaml"
        if [ -e "$np" ]; then
            echo -e "using $np"
            echo "network:" >> "$np"
            echo "  version: 2" >> "$np"
            echo "  ethernets:" >> "$np"
            for interface in $interfaces; do
                echo -e "    $interface:" >> "$np"
                echo "      dhcp4: true" >> "$np"
                echo "      dhcp6: false" >> "$np"
            done
            chown root:root "$np"
            chmod 600 "$np"
            netplan apply
            echo "Netplan configuration applied"
        fi
    elif [ $os_type == "RHEL" ]; then
        sysctl="/etc/sysctl.conf"
        if [ -e "$sysctl" ]; then
            echo "using sysctl"
            echo "net.ipv6.conf.all.disable_ipv6 = 1" >> "$sysctl"
            echo "net.ipv6.conf.default.disable_ipv6 = 1" >> "$sysctl"
            sysctl -p
        fi
        for interface in $interfaces; do
            sysconfig="/etc/sysconfig/network-scripts/ifcfg-$interface"
            if [ -e "$sysconfig" ]; then
                echo -e "using $sysconfig"
                echo "IPV6INIT=no" >> "$sysconfig"
            fi
        done
        service network restart
    fi
}

deleteBad(){
    find / -name ".rhost" -exec rm -rf {} \;
    find / -name "host.equiv" -exec rm -rf {} \;
    sudo find / -iname '*.xlsx' -delete
	sudo find / -iname '*.shosts' -delete
	sudo find / -iname '*.shosts.equiv' -delete
}

perms(){
    chmod 755 /etc/resolvconf/resolv.conf.d/
    chmod 644 /etc/resolvconf/resolv.conf.d/base
    chmod 777 /etc/resolv.conf
    chmod 644 /etc/hosts
    chmod 644 /etc/host.conf
    chmod 644 /etc/hosts.deny
    chmod 755 /etc/apt/
    chmod 755 /etc/apt/apt.conf.d/
    chmod 644 /etc/apt/apt.conf.d/10periodic
    chmod 644 /etc/apt/apt.conf.d/20auto-upgrades
    chmod 664 /etc/apt/sources.list
    chmod 644 /etc/default/ufw
    chmod 755 /etc/ufw/
    chmod 644 /etc/ufw/sysctl.conf
    chmod 755 /etc/sysctl.d/
    chmod 644 /etc/sysctl.conf
    chmod 644 /proc/sys/net/ipv4/ip_forward
    chmod 644 /etc/passwd
    chmod 640 /etc/shadow
    chmod 644 /etc/group
    chmod 640 /etc/gshadow
    chmod 755 /etc/sudoers.d/
    chmod 440 /etc/sudoers.d/*
    chmod 440 /etc/sudoers
    chmod 644 /etc/deluser.conf
    chmod 644 /etc/adduser.conf
    chmod 644 /etc/login.defs
    chmod 644 /etc/pam.d/common-auth
    chmod 644 /etc/pam.d/common-password
    chmod 755 /etc/rc.local
    chmod 755 /etc/grub.d/
    chmod 600 /etc/securetty
    chmod 644 /etc/security/limits.conf
    chmod 664 /etc/fstab
    chmod 644 /etc/updatedb.conf
    chmod 644 /etc/modprobe.d/blacklist.conf
    chmod 644 /etc/environment
    chmod 600 /boot/grub2/grub.cfg
    chmod 755 /etc
    chmod 755 /bin
    chmod 755 /boot
    chmod 775 /cdrom
    chmod 755 /dev
    chmod 755 /home
    chmod 755 /lib
    chmod 755 /media
    chmod 755 /mnt
    chmod 755 /opt
    chmod 555 /proc/
    chmod 700 /root
    chmod 755 /run
    chmod 755 /sbin
    chmod 755 /snap
    chmod 755 /srv
    chmod 555 /sys
    chmod 1755 /tmp
    chmod 755 /usr
    chmod 755 /var/
    chown root:root /etc/resolvconf/resolv.conf.d/
    chown root:root /etc/resolvconf/resolv.conf.d/base
    chown root:root /etc/resolv.conf
    chown root:root /etc/hosts
    chown root:root /etc/host.conf
    chown root:root /etc/hosts.deny
    chown root:root /etc/apt/
    chown root:root /etc/apt/apt.conf.d/
    chown root:root /etc/apt/apt.conf.d/10periodic
    chown root:root /etc/apt/apt.conf.d/20auto-upgrades
    chown root:root /etc/apt/sources.list
    chown root:root /etc/default/ufw
    chown root:root /etc/ufw/
    chown root:root /etc/ufw/sysctl.conf
    chown root:root /etc/sysctl.d/
    chown root:root /etc/sysctl.conf
    chown root:root /proc/sys/net/ipv4/ip_forward
    chown root:root /etc/passwd
    chown root:shadow /etc/shadow
    chown root:root /etc/group
    chown root:shadow /etc/gshadow
    chown root:root /etc/sudoers.d/
    chown root:root /etc/sudoers.d/*
    chown root:root /etc/sudoers
    chown root:root /etc/deluser.conf
    chown root:root /etc/adduser.conf
    chown root:root /etc/login.defs
    chown root:root /etc/pam.d/common-auth
    chown root:root /etc/pam.d/common-password
    chown root:root /etc/rc.local
    chown root:root /etc/grub.d/
    chown root:root /etc/securetty
    chown root:root /etc/security/limits.conf
    chown root:root /etc/fstab
    chown root:root /etc/updatedb.conf
    chown root:root /etc/modprobe.d/blacklist.conf
    chown root:root /etc/environment
    chown root:root /boot/grub2/grub.cfg
    chown root:root /etc
    chown root:root /bin
    chown root:root /boot
    chown root:root /cdrom
    chown root:root /dev
    chown root:root /home
    chown root:root /lib
    chown root:root /media
    chown root:root /mnt
    chown root:root /opt
    chown root:root /proc/
    chown root:root /root
    chown root:root /run
    chown root:root /sbin
    chown root:root /snap
    chown root:root /srv
    chown root:root /sys
    chown root:root /tmp
    chown root:root /usr
    chown root:root /var/
}

chattr(){
    chattr +ia /etc/passwd
    chattr +ia /etc/group
    chattr +ia /etc/shadow
    chattr +ai /etc/passwd-
    chattr +ia /etc/group-
    chattr +ia /etc/shadow-
}


# main

backups
fix_corrupt
reset_environment
sed_ssh
check_ssh_keys
kernel
aliases
configCmds
noIpv6
perms

#last thing absolutely last
chattr

# add more here

