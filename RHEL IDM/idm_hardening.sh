#!/bin/bash

echo "NOTICE: This script must be run on the IDM domain controller"
#Password prompt:
read -s -p "Please enter current password for IDM Domain Admin: " PASS < /dev/tty
echo -e "\n" #Newline for formatting; can be removed if necessary
echo $PASS|kinit admin #Get Kerberos ticket
export HOSTNAME=$(hostname)
#Disables anonymous LDAP binds from reading directory data while still allowing binds to root DSE information needed to get connection info (using LDAPS):
echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-allow-anonymous-access\nnsslapd-allow-anonymous-access: rootdse\n" | ldapmodify -x -D "cn=Directory Manager" -w -H "ldaps://$HOSTNAME:636"
ipa krbtpolicy-mod --maxlife=$((1*60*60)) --maxrenew=$((5*60*60)) #Change Kerberos global ticket policy time (max life of 1 hour and max renew of 5 hours)

read -s -p "Please enter new password for IDM Domain Admin: " NEW_PASS < /dev/tty
echo -e "$NEW_PASS\n$NEW_PASS"|ipa user-mod admin --password
read -s -p "Please enter current LDAP Directory Manager Password: " LDAP_PASS < /dev/tty
read -s -p "Please enter new LDAP Directory Manager Password: " NEW_LDAP_PASS < /dev/tty
echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-rootpw\nnsslapd-rootpw: $NEW_LDAP_PASS\n\n"|ldapmodify -x -H "ldaps://$HOSTNAME:636" -D "cn=directory manager" -w $LDAP_PASS

systemctl restart dirsrv.target #Restarts service for changes to take effect
service krb5kdc restart #restarts Kerberos for changes to take effect


#To-dos: 
#   Maybe add a check version feature to see if vulnerable to CVE-2020–10747 (kind of irrelevant if proper ssh hardening is done so not critical)