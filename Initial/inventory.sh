#!/bin/bash
##Hal Williams
#ima try and make this better based on our insperation, credit @d_tranman

#WIP
#todo, SUID, worldwritiable, sudogroup, services, more?, print everything, expand the distributions detected

#OS variable initialization
DEBIAN=false
REDHAT=false
ALPINE=false
SLACK=false
AMZ=false

#Debian distributions
UBUNTU=false
#MINT=false
#ELEMENTARY=false
#KALI=false
#RASPBIAN=false
#PROMOXVE=false
#ANTIX=false

#Red Hat Distributions
RHEL=false
#CENTOS=false
#FEDORA=false
#ORACLE=false
#ROCKY=false
#ALMA=false

#Alpine Distributions
#ADELIE=false
#WSL=false

#sets OS and distribution, distribution needs to be tested on a instance of each
DEBIAN(){
    DEBIAN=true
    #Determine distribution
    if grep -qi Ubuntu /etc/os-release ; then
        UBUNTU=true
    fi
    #add more for each debian distro later
}
REDHAT(){
    REDHAT=true
    #Determine distribution
    if [ -e /etc/redhat-release ] ; then
        RHEL=true
    fi
}
ALPINE(){
    ALPINE=true
    #Determine distribution
}
SLACK(){
    SLACK=true
    #Determine distribution
}
AMZ(){
    AMZ=true
}

#Determines OS
if [ -e /etc/debian_version ] ; then
    DEBIAN
elif [ -e /etc/redhat-release ] ; then
    REDHAT
elif [ -e /etc/alpine-release ] ; then
    ALPINE
elif [ -e /etc/slackware-version ] ; then 
    SLACK
#This one def needs tested but I dont have access to amazon linux till i can get back to school.
elif [ -e /etc/system-release ] ; then
    AMZ
fi

#Host info gathering
#get hostname
HOSTNAME=$(hostname || cat /etc/hostname)
#get OS version
OS=$( cat /etc/*-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//' | sed 's/"//g' )
#get ipddress
IP=$( (ip a | grep -oE '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}/[[:digit:]]{1,2}' | grep -v '127.0.0.1') || { ifconfig | grep -oE 'inet.+([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | grep -v '127.0.0.1'; } )
#get users
USERS=$( cat /etc/passwd | grep -vE '(false|nologin|sync)$' | grep -E '/.*sh$' )
#get sudoers
SUDOERS=$(grep -h -vE '#|Defaults|^\s*$' /etc/sudoers /etc/sudoers.d/* | grep -vE '(Cmnd_Alias|\\)')
#get sudo groups
if [ $REDHAT = true ] || [ $ALPINE = true ]; then
    SUDOGROUP=$( cat /etc/group | grep wheel | sed 's/x:.*:/\ /' )
else
    SUDOGROUP=$( cat /etc/group | grep sudo | sed 's/x:.*:/\ /' )
fi
#get suid
SUIDS=$(find /bin /sbin /usr -perm -u=g+s -type f -exec ls -la {} \; | grep -E '(s7z|aa-exec|ab|agetty|alpine|ansible-playbook|ansible-test|aoss|apt|apt-get|ar|aria2c|arj|arp|as|ascii85|ascii-xfr|ash|aspell|at|atobm|awk|aws|base32|base58|base64|basenc|basez|bash|batcat|bc|bconsole|bpftrace|bridge|bundle|bundler|busctl|busybox|byebug|bzip2|c89|c99|cabal|cancel|capsh|cat|cdist|certbot|check_by_ssh|check_cups|check_log|check_memory|check_raid|check_ssl_cert|check_statusfile|chmod|choom|chown|chroot|clamscan|cmp|cobc|column|comm|composer|cowsay|cowthink|cp|cpan|cpio|cpulimit|crash|crontab|csh|csplit|csvtool|cupsfilter|curl|cut|dash|date|dd|debugfs|dialog|diff|dig|distcc|dmesg|dmidecode|dmsetup|dnf|docker|dos2unix|dosbox|dotnet|dpkg|dstat|dvips|easy_install|eb|ed|efax|elvish|emacs|enscript|env|eqn|espeak|ex|exiftool|expand|expect|facter|file|find|finger|fish|flock|fmt|fold|fping|ftp|gawk|gcc|gcloud|gcore|gdb|gem|genie|genisoimage|ghc|ghci|gimp|ginsh|git|grc|grep|gtester|gzip|hd|head|hexdump|highlight|hping3|iconv|iftop|install|ionice|ip|irb|ispell|jjs|joe|join|journalctl|jq|jrunscript|jtag|julia|knife|ksh|ksshell|ksu|kubectl|latex|latexmk|ldconfig|ld.so|less|lftp|ln|loginctl|logsave|look|lp|ltrace|lua|lualatex|luatex|lwp-download|lwp-request|mail|make|man|mawk|minicom|more|mosquitto|msfconsole|msgattrib|msgcat|msgconv|msgfilter|msgmerge|msguniq|mtr|multitime|mv|mysql|nano|nasm|nawk|nc|ncftp|neofetch|nft|nice|nl|nm|nmap|node|nohup|npm|nroff|nsenter|octave|od|openssl|openvpn|openvt|opkg|pandoc|paste|pax|pdb|pdflatex|pdftex|perf|perl|perlbug|pexec|pg|php|pic|pico|pidstat|pip|pkexec|pkg|posh|pr|pry|psftp|psql|ptx|puppet|pwsh|python|rake|rc|readelf|red|redcarpet|redis|restic|rev|rlogin|rlwrap|rpm|rpmdb|rpmquery|rpmverify|rsync|rtorrent|ruby|run-mailcap|run-parts|runscript|rview|rvim|sash|scanmem|scp|screen|script|scrot|sed|service|setarch|setfacl|setlock|sftp|sg|shuf|slsh|smbclient|snap|socat|socket|soelim|softlimit|sort|split|sqlite3|sqlmap|ss|ssh|ssh-agent|ssh-keygen|ssh-keyscan|sshpass|start-stop-daemon|stdbuf|strace|strings|sysctl|systemctl|systemd-resolve|tac|tail|tar|task|taskset|tasksh|tbl|tclsh|tcpdump|tdbtool|tee|telnet|terraform|tex|tftp|tic|time|timedatectl|timeout|tmate|tmux|top|torify|torsocks|troff|tshark|ul|unexpand|uniq|unshare|unsquashfs|unzip|update-alternatives|uudecode|uuencode|vagrant|valgrind|vi|view|vigr|vim|vimdiff|vipw|virsh|volatility|w3m|wall|watch|wc|wget|whiptail|whois|wireshark|wish|xargs|xdg-user-dir|xdotool|xelatex|xetex|xmodmap|xmore|xpad|xxd|xz|yarn|yash|yelp|yum|zathura|zip|zsh|zsoelim|zypper)$')
#get worldwritables
WORLDWRITABLE=$( find /usr /bin/ /sbin /var/www/ lib -perm -o=w -type f -exec ls {} -la \; )

echo -e "Inventory\n"

echo -e "\nHost Info\n"
echo -e "Hostname: $HOSTNAME"
echo -e "OS: $OS"
echo -e "IP Addresses/Interfaces: $IP"
echo -e "Users: $USERS"
echo -e "Sudoers: $SUDOERS"
echo -e "Sudo Group Users: $SUDOGROUP"
echo -e "SUIDS: $SUIDS"
echo -e "World Writable Files: $WORLDWRITABLE"

#this might go to the services script that ima make tomorrow
#Listening ports
PORTS=$( netstat -tlpn | tail -n +3 | awk '{print $1 " " $4 " " $6 " " $7}' | column -t || ss -blunt -p | tail -n +2 | awk '{print $1 " " $5 " " $7}' | column -t )

echo -e "\nListening Ports: $PORTS"

