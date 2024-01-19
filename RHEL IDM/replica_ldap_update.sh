#!/bin/bash

#Source: https://www.freeipa.org/page/Howto/Change_Directory_Manager_Password
#Purpose: Must be run on IdM replicas after changing LDAP Directory Manager password to propogate change to PKI

#Set environment variables:
export KEYDB_PIN=$(cat /etc/pki/pki-tomcat/password.conf|grep "internal="|awk -F '=' '{print $2}')
export ALIAS_PATH=/var/lib/pki/pki-tomcat/alias/
export CA_PORT=389
read -s -p "Please enter LDAP Directory Manager Password: " DM_PASSWORD < /dev/tty

#Step 1: 
#COME BACK TO LATER

#Step 2:
echo -n $DM_PASSWORD > /root/dm_password
echo -n $KEYDB_PIN > /root/keydb_pin
/usr/bin/PKCS12Export -d $ALIAS_PATH -p /root/keydb_pin -w /root/dm_password -o /root/cacert.p12

#Step 3: 

#Step 4 (cleanup):
rm /root/dm_password
rm /root/keydb_pin



