#!/bin/bash
#Hal Williams
#Based on a similar inventory script by another team : credit @d_tranman
#WIP
#todo: expand the distributions detected
#Notes Need to be Sudo

exec 2>/dev/null

# Import the OS variables
# Needs os_detection.sh to run first
PATH_TO_OS_RESULTS_FILE="./os.txt"
if [ -f $PATH_TO_OS_RESULTS_FILE ] ; then
    source $PATH_TO_OS_RESULTS_FILE
else
    echo "Operating System information file (as produced by os_detection.sh) not found! Exiting..."
    exit
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

echo -e "--Host Info--"
echo -e "Hostname: $HOSTNAME"
echo -e "OS: $OS"
echo -e "IP Addresses/Interfaces: \n$IP"
echo -e "Users: \n$USERS"
echo -e "Sudoers: \n$SUDOERS"
echo -e "Sudo Group Users: \n$SUDOGROUP"
echo -e "SUIDS: \n$SUIDS"
echo -e "World Writable Files: \n$WORLDWRITABLE"

#this might go to the services script that ima make tomorrow
#Listening ports
PORTS=$( netstat -tlpn | tail -n +3 | awk '{print $1 " " $4 " " $6 " " $7}' | column -t || ss -blunt -p | tail -n +2 | awk '{print $1 " " $5 " " $7}' | column -t )

echo -e "\nListening Ports: $PORTS"

#Services
#lsof wont be able to show the port(s) if this isnt run as sudo
checkService(){
	serviceList=$( systemctl --type=service | grep active | awk '{print $1}' || service --status-all | grep -E '(+|is running)' )
	service=$1

	if echo "$serviceList" | grep -qi "$service"; then
		echo -e "$service is on this machine"
		PID=$(systemctl show -p MainPID --value $service)
		echo -e "$service is listening on $(lsof -i -P -n -a -p "$PID" | grep LISTEN | awk '{print $9}' | awk -F ":" '{print $NF}' | sort -u )"
		return 1
	fi
	return 0
}

checkService 'ssh'; SSH=$?
checkService 'apache2'; APACHE=$?
checkService 'nginx'; NGINX=$?
checkService 'docker'; DOCKER=$?
checkService 'ftp'; FTP=$?
checkService 'pure-ftpd'; PUREFTPD=$?
checkService 'proftpd'; PROFTPD=$?
checkService 'vsftpd'; VSFTPD=$?
checkService 'tftpd'; TFTPD=$?
checkService 'atftpd'; ATFTPD=$?
checkService 'mysql'; MYSQL=$?
checkService 'mariadb'; MARIADB=$?
checkService 'postgres'; POSTGRES=$?
checkService 'httpd'; HTTPD=$?
checkService 'php'; PHP=$?
checkService 'python'; PYTHON=$?
checkService 'xinetd'; XINETD=$?
checkService 'inetd'; INETD=$?
checkService 'smbd'; SMBD=$?
checkService 'nmbd'; NMBD=$?
checkService 'ypbind'; YPBIND=$?
checkService 'rshd'; RSHD=$?
checkService 'rexecd'; REXECD=$?
checkService 'rlogin'; RLOGIN=$?
checkService 'telnet'; TELNET=$?
checkService 'squid'; SQUID=$?
checkService 'dropbear'; DROPBEAR=$?
checkService 'cockpit'; COCKPIT=$?
checkService 'cron'; CRON=$?
checkService 'atd'; ATD=$?
checkService 'cupsd'; CUPSD=$?
checkService 'avahi-daemon'; AVAHI-DAEMON=$?