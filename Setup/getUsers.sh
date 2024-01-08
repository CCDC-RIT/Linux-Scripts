#!/bin/bash
# by: Justin Huang (jznn)

# Objective: get a list of users with valid login shells and store them line by line in a file to be used as input for users.sh
# usage: ./getUsers.sh [any usernames for users with information you do not want to change, separated by spaces]
# NOTE: MAKE SURE YOU READ OVER USERS.TXT AFTER RUNNING THIS AND REMOVE ALL USERS WHOSE INFORMATION YOU DO NOT WANT TO CHANGE (e.g. root, your own user, white team)

user_list=$(grep -E "/bin/(bash|sh|zsh|fish)" /etc/passwd | cut -d':' -f1); # shells to check for

for user in $user_list; do
    if [[ ! "$@" =~ "$user" ]]; then
        echo "$user" >> users.txt
    fi
done