#!/bin/bash

###########################
## Must run as superuser ##
###########################
if [ "$EUID" -ne 0 ]; then 
  echo "Must run as superuser"
  exit
fi

# Clean Up the Output of some 
# Look into Autoruns, Potetal Rootkits, Auth backdoors

sl="sleep"
s="sudo"
t="0s"

timestamp() {
  
  echo -e "\n\n-------- $(date) --------\n\n"
}

basic(){
    echo -e "\n-------------\n > Aliases <\n------------- "
    alias
    sleep $t

    echo -e "\n---------------------\n > Checking for Shims <\n---------------------"
    diff /bin/false /bin/sh
    diff /bin/false /bin/bash    
    diff /usr/sbin/nologin /bin/sh
    diff /usr/sbin/nologin /bin/bash
    diff /usr/bin/passwd /bin/passwd
    diff /usr/bin/ls /bin/ls
    diff /usr/bin/sudo /bin/sudo
    sleep $t

    echo -e "\n--------------\n > SSH Keys <\n-------------- "
    # TODO - LIST THE KEY NAMES / NUMBER OF KEYS
    $s cat /root/ssh/sshd_config | grep -i AuthorizedKeysFile
    $s head -n 20 /home/*/.ssh/authorized_keys*
    $s head -n 20 /root/.ssh/authorized_keys*
    sleep $t

    echo -e "\n-------------------------\n > Currently Logged In <\n------------------------- "
    $s who
    $s w
    sleep $t

    echo -e "\n-------------------\n > login history <\n------------------- "
    $s last | grep -Ev 'system' | head -n 20
    sleep $t

    echo -e "\n-------------------------------\n > Current Network Listening <\n------------------------------- "
    $s ss -tulpnw
    sleep $t

    echo -e "\n-----------------\n > lsof Remote <\n----------------- "
    $s lsof -i
    sleep $t

    echo -e "\n----------------------------\n > Potental Rootkit Signs <\n---------------------------- "
    $s dmesg | grep taint
    $s env | grep -i 'LD'
    sleep $t

    echo -e "\n-----------------------\n > Mounted Processes <\n----------------------- "
    $s mount | grep "proc"
    sleep $t

}

verbose(){
    
    echo -e "\n-------------\n > Auto Runs <\n\n------------- "
    $s cat /etc/crontab | grep -Ev '#|PATH|SHELL'
    $s cat /etc/cron.d/* | grep -Ev '#|PATH|SHELL'
    $s find /var/spool/cron/crontabs/ -printf '%p\n' -exec cat {} \;
    $s systemctl list-timers
    sleep $t

    echo -e "\n--------------\n > lsof Raw <\n-------------- "
    $s lsof | grep -i -E 'raw|pcap'
    $s lsof | grep /proc/sys/net/ipv4
    sleep $t

    echo -e "\n---------------\n > Processes <\n--------------- "
    $s ps af
    sleep $t

    echo -e "\n-------------------------\n > Poisoned Networking <\n------------------------- "
    $s cat /etc/nsswitch.conf
    $s cat /etc/hosts
    $s cat /etc/resolv.conf | grep -Ev '#|PATH|SHELL'
    $s ip netns list
    $s ip route
    sleep $t

    echo -e "\n---------------\n > Ips and macs <\n--------------- "
    ip -c route | grep "default"
    echo -e ""
    ip -br -c a
    echo -e "\n[MAC]"
    ip -br -c link

    echo -e "\n---------------\n > Services <\n--------------- "
    $s find /etc/systemd/system -name "*.service" -exec cat {} + | grep ExecStart | cut -d "=" -f2  | grep -Ev "\!\!" 
    sleep $t

    echo -e "\n--------------------\n > Auth Backdoors <\n-------------------- "
    $s cat /etc/sudoers | grep NOPASS
    $s cat /etc/sudoers | grep !AUTH
    $s find / -type f \( -name ".rhosts" -o -name ".shosts" -o -name "hosts.equiv" \) -exec ls -l {} \;
    sleep $t

    echo -e "\n------------------------------\n > Files Modified Last 10Min <\n------------------------------ "
    echo -e "/etc"
    $s find / -xdev -mmin -10 -ls 2> /dev/null
    echo -e "/home"
    $s find /home -xdev -mmin -10 -ls 2> /dev/null
    echo -e "/root"
    $s find /root -xdev -mmin -10 -ls 2> /dev/null
    echo -e "/bin"
    $s find /bin -xdev -mmin -10 -ls 2> /dev/null
    echo -e "/sbin"
    $s find /sbin -xdev -mmin -10 -ls 2> /dev/null
    sleep $t

    echo -e "\n------------------\n > Repositories <\n------------------ "
    $s cat /etc/apt/sources.list | grep -Ev "##|#"
    sleep $t

    echo -e "\n------------------\n > Malware? <\n------------------"
    OS=$(cat /etc/os-release | grep "PRETTY_NAME" | grep -o "\".*.\"" | tr -d '"')
    if [ "$OS" == "Ubuntu" ]; then
      dpkg -l | grep "sniff"
      dpkg -l | grep "packet" 
      dpkg -l | grep "wireless" 
      dpkg -l | grep "pen"
      dpkg -l | grep "test" 
      dpkg -l | grep "password" 
      dpkg -l | grep "crack"
      dpkg -l | grep "spoof" 
      dpkg -l | grep "brute" 
      dpkg -l | grep "log" 
      dpkg -l | grep "key"
      dpkg -l | grep "network" 
      dpkg -l | grep "map" 
      dpkg -l | grep "server"
      dpkg -l | grep "CVE" 
      dpkg -l | grep "exploit" 
    else
      echo "this approach dont work for RHEL cope"
    fi

    echo -e "\n------------------\n > Running external audit scripts <\n------------------"
    echo -e "\n------------------\n > Linpeas - output to linpeas.txt <\n------------------"
    curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh > linpeas.txt
    echo -e "\n------------------\n > Lynis - output to lynis.txt <\n------------------"
    lynis audit system > lynis.txt
}

# Get User Input to get sleep time and Type
timestamp
echo -ne "Enter Option (Default : Basic)\n1) Basic Mode\n2) Verbose Mode\n\n : "
read opt
echo -n "Pause Time For Each Section (Default 0) : "
read sec

# Set Pause Time
if [[ -n $sec ]]; then
  t=${sec}s
fi

# Run User Selected Mode
if [[ $opt == 1 ]]; then 
  basic
  exit 0
else
  basic
  verbose
  exit 0
fi

## TODO ##
