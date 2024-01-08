#!/bin/bash
# by: Justin Huang (jznn)

# Objective: provides option for user to change passwords and disable users
# Suggestion: do not use change all and disable all functionalities, as there should always be exceptions that should not be disabled or changed (ex: blue/white team users)
# don't ask why i added the functionality if i'm never going to use it

# TODO: add RHEL IDM functionality, add exception for white team user and other scoring user (potentially just omit from selected user list)
# TODO: test run

# grab list of users
user_list=$(grep "bash" /etc/passwd | cut -d':' -f1); # only counts users with /bin/bash as their login shell, can potentially be changed later to do all users
# note: i don't think it'd be a good idea to have it include ALL users, as changing stuff for system users and scoring users could be catastrophic

# print list of users to stdout
list_users(){
    echo "Current Users: "
    for user in $user_list
    do
        echo $user
    done
}

# change passwords for all user accounts
change_all()
{   
    # prompt for password to be used
    read -s -p "Please enter password to be added to new user: " PASS < /dev/tty
	echo "setting passwords"
	for user in $user_list; do
		passwd -q -x 85 $user > /dev/null; # password aging controls because why not
		passwd -q -n 15 $user > /dev/null;
		echo $user:$PASS | chpasswd; 
		chage --maxdays 15 --mindays 6 --warndays 7 --inactive 5 $user;
	done;
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

# disable all users and change shell
disable_all() {
    for user in $user_list; do
		passwd -l $user; # disable password login
        chsh -s /bin/redd $user # changing to honeypot shell
	done;
}

disable_users(){
    read -p "Provide the name of a file containing the usernames of each user who should be disabled, one per line" user_file
    if [ ! -f "$user_file" ]; then
        echo "Error: File not found."
    return 1
    fi
    while IFS= read -r user; do
        if [ -n "$user" ]; then
            passwd -l $user; # disable password login
            chsh -s /bin/redd $user # changing to honeypot shell
        fi
}

# function to display options for user input
display_options() {
    echo "Menu:"
    echo "1. List all users, including system users, in /etc/passwd"
    echo "2. Change passwords for all users"
    echo "3. Change password for certain users (provide file)"
    echo "4. Disable all users and apply proper user properties"
    echo "5. Disable certain users (provide file) and apply proper user properties"
    echo "6. Exit"
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
    display_menu
    handle_input
done