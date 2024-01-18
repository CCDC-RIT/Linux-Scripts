#!/bin/bash

#Password prompt:
echo "NOTICE: This script must be run on the IDM domain controller"
read -s -p "Please enter password for IDM Domain Admin: " PASS < /dev/tty
echo -e "\n" #Newline for formatting; can be removed if necessary
echo $PASS|kinit admin #Get Kerberos ticket
export HOSTNAME=$(hostname)
#Disables anonymous LDAP binds from reading directory data while still allowing binds to root DSE information needed to get connection info:
echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-allow-anonymous-access\nnsslapd-allow-anonymous-access: rootdse\n" | ldapmodify -x -D "cn=Directory Manager" -W -h $HOSTNAME -p 389 
ipa krbtpolicy-mod --maxlife=$((1*60*60)) --maxrenew=$((5*60*60)) #Change Kerberos global ticket policy time
systemctl restart dirsrv.target #Restarts service for changes to take effect


