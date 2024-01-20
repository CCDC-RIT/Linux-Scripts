#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Run As Sudo"
  exit
fi

change_idm_admin(){
    read -s -p "Please enter current password for IDM Domain Admin: " PASS < /dev/tty
    echo $PASS|kinit admin #Get Kerberos ticket
    echo -e "\n" #Newline for formatting; can be removed if necessary
    read -s -p "Please enter new password for IDM Domain Admin: " NEW_PASS < /dev/tty
    echo -e "$NEW_PASS\n$NEW_PASS"|ipa user-mod admin --password
}

change_ldap_manager_password(){
    export HOSTNAME=$(hostname)
    read -s -p "Please enter current password for IDM Domain Admin: " PASS < /dev/tty
    echo $PASS|kinit admin #Get Kerberos ticket
    read -s -p "Please enter current LDAP Directory Manager Password: " LDAP_PASS < /dev/tty
    read -s -p "Please enter new LDAP Directory Manager Password: " NEW_LDAP_PASS < /dev/tty
    echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-rootpw\nnsslapd-rootpw: $NEW_LDAP_PASS\n\n"|ldapmodify -x -H "ldaps://$HOSTNAME:636" -D "cn=directory manager" -w $LDAP_PASS
}

idm_hardening(){
    export HOSTNAME=$(hostname)
    read -s -p "Please enter current password for IDM Domain Admin: " PASS < /dev/tty
    echo $PASS|kinit admin #Get Kerberos ticket
    #Disables anonymous LDAP binds from reading directory data while still allowing binds to root DSE information needed to get connection info (using LDAPS):
    echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-allow-anonymous-access\nnsslapd-allow-anonymous-access: rootdse\n\n" | ldapmodify -x -D "cn=Directory Manager" -W -H "ldaps://$HOSTNAME:636"
    #Make passwords not ask user to reset after changed by admin:
    # Extract the FQDN parts
    IFS='.' read -ra parts <<< "$HOSTNAME"
    export UNO="${parts[${#parts[@]}-2]}"
    export DOS="${parts[${#parts[@]}-1]}"
    echo -e "dn: cn=ipa_pwd_extop,cn=plugins,cn=config\nchangetype: modify\nadd: passSyncManagersDNs\npassSyncManagersDNs: uid=admin,cn=users,cn=accounts,dc=$UNO,dc=$DOS\n\n"|ldapmodify -x -D "cn=Directory Manager" -W -H "ldaps://$HOSTNAME:636"
    ipa krbtpolicy-mod --maxlife=$((1*60*60)) --maxrenew=$((5*60*60)) #Change Kerberos global ticket policy time (max life of 1 hour and max renew of 5 hours)
    #Edits global password policy:
    ipa pwpolicy-mod --minclasses=3 --history=5 --minlength=12 --maxfail=5 --gracelimit=0 --maxsequence=3 --lockouttime=600 --maxlife=60 --failinterval=600 --usercheck=true --dictcheck=true
    systemctl restart dirsrv.target > /dev/null #Restarts service for changes to take effect
    service krb5kdc restart > /dev/null #restarts Kerberos for changes to take effect 
}

display_options() {
    echo "Menu:"
    echo "1. Apply RHEL IdM Hardening Settings"
    echo "2. Change IdM Domain admin Password"
    echo "3. Change LDAP Directory Manager Password"
    echo "4. All of The Above" 
    echo "5. Exit"
}

ALL(){
    export HOSTNAME=$(hostname)
    read -s -p "Please enter current password for IDM Domain Admin: " PASS < /dev/tty
    read -s -p "Please enter current LDAP Directory Manager Password: " LDAP_PASS < /dev/tty
    echo $PASS|kinit admin #Get Kerberos ticket
    echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-allow-anonymous-access\nnsslapd-allow-anonymous-access: rootdse\n" | ldapmodify -x -D "cn=Directory Manager" -w $LDAP_PASS -H "ldaps://$HOSTNAME:636"
    IFS='.' read -ra parts <<< "$HOSTNAME"
    export UNO="${parts[${#parts[@]}-2]}"
    export DOS="${parts[${#parts[@]}-1]}"
    echo -e "dn: cn=ipa_pwd_extop,cn=plugins,cn=config\nchangetype: modify\nadd: passSyncManagersDNs\npassSyncManagersDNs: uid=admin,cn=users,cn=accounts,dc=$UNO,dc=$DOS\n\n"|ldapmodify -x -D "cn=Directory Manager" -w $LDAP_PASS -H "ldaps://$HOSTNAME:636"
    ipa krbtpolicy-mod --maxlife=$((1*60*60)) --maxrenew=$((5*60*60)) #Change Kerberos global ticket policy time (max life of 1 hour and max renew of 5 hours)
    ipa pwpolicy-mod --minclasses=3 --history=5 --minlength=12 --maxfail=5 --gracelimit=0 --maxsequence=3 --lockouttime=600 --maxlife=60 --failinterval=600 --usercheck=true --dictcheck=true
    echo -e "\n" #Newline for formatting; can be removed if necessary
    read -s -p "Please enter new password for IDM Domain Admin: " NEW_PASS < /dev/tty
    echo -e "$NEW_PASS\n$NEW_PASS"|ipa user-mod admin --password
    read -s -p "Please enter new LDAP Directory Manager Password: " NEW_LDAP_PASS < /dev/tty
    echo -e "dn: cn=config\nchangetype: modify\nreplace: nsslapd-rootpw\nnsslapd-rootpw: $NEW_LDAP_PASS\n\n"|ldapmodify -x -H "ldaps://$HOSTNAME:636" -D "cn=directory manager" -w $LDAP_PASS
    systemctl restart dirsrv.target > /dev/null #Restarts service for changes to take effect
    service krb5kdc restart > /dev/null #restarts Kerberos for changes to take effect
}

handle_input(){
    read -p "Enter an option: " choice
    case $choice in
        1)
            idm_hardening
            ;;
        2)
            change_idm_admin
            ;;
        3)
            change_ldap_manager_password
            ;;
        4)
            ALL
            ;;
        5) 
            echo "Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac
}

# Main:
echo "NOTICE: This script must be run on the IDM domain controller"
while true; do
    display_options
    handle_input
done
#CHANDI FORTNITE