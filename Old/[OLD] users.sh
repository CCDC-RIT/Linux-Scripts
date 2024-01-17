#!/bin/sh
# This script iterates over every user on the machine and asks to disable, and change password.

# Get a list of all users on the machine
user_list=$(cat /etc/passwd | cut -d ":" -f 1)

echo "Current Users: "
for user in $user_list
do
echo $user
done

# Iterate over each user
for user in $user_list
do
    # Ask to disable the user
    read -p "Disable user: $user (y/n)" disableUser
    case $disableUser in
        # Disable the user
        y|Y) usermod -L $user # Lock the user 
        usermod --expiredate 1 $user # Set the expiration date to yesterday 
        usermod -s /sbin/nologin $user # Set the shell to nologin 
        usermod -c "Disabled user" $user # Set the comment to "Disabled user" 
        echo "Disabled $user" ;;
    esac

    # Ask to change the password
    read -p "Change password: $user (y/n)" change
    case $change in
        y|Y)
        # Change the password with one line from the user
        read -p "Enter new password for $user: " password 
        echo "$user:$password" | chpasswd
        echo "Password changed to $password" ;;
    esac

done
