#!/bin/bash
# by: Justin Huang (jznn)

# Objective: provides option for user to change passwords and disable users
# Pre-condition: a file called users.txt exists in the same directory, with a list of users whose information should be changed (can be obtained by running getUsers.sh)
# Additional pre-condition for RHEL IDM functionality: Valid Kerberos ticket (obtained by using the "kinit admin" command) and a file called idm_users.txt exists in the current directory, which can be created by running getIDMusers.sh or idm_usersAndGroups.sh

# TODO: add RHEL IDM functionality
# TODO: test run

# print list of users to stdout
if [ "$EUID" -ne 0 ]; then 
  echo "Run as sudo to prevent lockout"
  exit
fi

list_users() {
    echo "Current Users: "
    while IFS= read -r user; do
        echo "$user"
    done < users.txt
}

list_idm_users() {
	#Derived from list_users but changed slightly to incorporate RHEL IDM functionality 
	echo "RHEL IDM Users: "
	while IFS= read -r user; do
        echo "$user"
    done < idm_users.txt
	
}

# change passwords for all user accounts in users.txt 
change_all()
{   
    # prompt for password to be used
    read -s -p "Please enter password to be added to new user: " PASS < /dev/tty
	echo "setting passwords"
	while IFS= read -r user; do
		passwd -q -x 85 $user > /dev/null; # password aging controls because why not
		passwd -q -n 15 $user > /dev/null;
		echo $user:$PASS | chpasswd; 
		chage --maxdays 15 --mindays 6 --warndays 7 --inactive 5 $user;
	done < users.txt
}

change_all_idm()
{   
    # prompt for password to be used
    read -s -p "Please enter new password: " PASS < /dev/tty
	echo "Setting passwords..."
	while IFS= read -r user; do
        echo -e "$PASS\n$PASS"|ipa user-mod $user --password #Pipes in the provided password to the password prompt
	done < idm_users.txt
    echo "Done."
}


change_passwords_idm(){ 
    read -p "Provide the name of a file containing the usernames of each IDM user whose password you want to change, one per line" user_file
    if [ ! -f "$user_file" ]; then
        echo "Error: File not found."
        return 1
    fi
    # prompt for password to be used
    read -s -p "Please enter password to be added to new user: " PASS < /dev/tty
    # Read each line from the file and change the password for each user
    while IFS= read -r user; do
        if [ -n "$user" ]; then
            echo "Changing password for user: $user"
            echo -e "$PASS\n$PASS"|ipa user-mod $user --password
        fi
    done < "$user_file"
}


# change passwords for certain users
change_passwords(){ 
    read -p "Provide the name of a file containing the usernames of each user whose password you want to change, one per line" user_file
    if [ ! -f "$user_file" ]; then
        echo "Error: File not found."
        return 1
    fi
    # prompt for password to be used
    read -s -p "Please enter password to be added to new user: " PASS < /dev/tty
    # Read each line from the file and change the password for each user
    while IFS= read -r user; do
        if [ -n "$user" ]; then
            echo "Changing password for user: $user"
            passwd -q -x 85 $user > /dev/null;
		    passwd -q -n 15 $user > /dev/null;
		    echo $user:$PASS | chpasswd;
            chage --maxdays 15 --mindays 6 --warndays 7 --inactive 5 $user;
        fi
    done < "$user_file"
}

# disable all users in users.txt and change shell
disable_all() {
    while IFS= read -r user; do
        usermod --expiredate 1 $user # Set the expiration date to yesterday 
		passwd -l $user; # disable password login
        chsh -s /bin/redd $user # changing to honeypot shell
	done < users.txt
}

#Disables all IDM user accounts in idm_users.txt
disable_all_idm() {
    #To-do: force Kerberos ticket expiry as existing connections remain valid until the ticket expires
    while IFS= read -r user; do
        ipa user-disable $user #Note: this user will still show up when retrieving users although it is disabled, as it has not been deleted. These users cannot authenticate and use any Kerberos services or do any tasks while the IDM account is disabled
	done < idm_users.txt
}

disable_users(){
    read -p "Provide the name of a file containing the usernames of each user who should be disabled, one per line" user_file
    if [ ! -f "$user_file" ]; then
        echo "Error: File not found."
        return 1
    fi
    while IFS= read -r user; do
        if [ -n "$user" ]; then
            usermod --expiredate 1 $user # Set the expiration date to yesterday 
            passwd -l "$user"; # disable password login
            chsh -s /bin/redd "$user" # changing to honeypot shell
        fi
    done < "$user_file"
}

# function to display options for user input
display_options() {
    echo "Menu:"
    echo "1. List all users with valid shells in /etc/passwd"
    echo "2. Change passwords for all users in list"
    echo "3. Change password for certain users (provide file)"
    echo "4. Disable all users in list and apply proper user properties"
    echo "5. Disable certain users (provide file) and apply proper user properties"
	echo "6. List all users in the RHEL IDM domain"
    echo "7. Change passwords for all IDM users"
    echo "8. Change passwords for certain IDM users (provide file)"
    echo "9. Disable all IDM users in list"
    echo "10. Exit"
}

# function to handle user input
handle_input() {
    read -p "Enter an option: " choice
    case $choice in
        1)
            list_users
            ;;
        2)
            change_all
            ;;
        3)
            change_passwords
            ;;
        4)
            disable_all
            ;;
        5)
            disable_users
            ;;
		6)
			list_idm_users
			;;
        7)
            change_all_idm
            ;;
        8)
            change_passwords_idm
            ;;
        9)
            disable_all_idm
            ;;
        10)
            echo "Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac
}

# Main loop
while true; do
    display_options
    handle_input
done