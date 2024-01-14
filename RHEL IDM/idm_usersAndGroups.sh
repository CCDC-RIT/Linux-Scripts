#!/bin/bash
echo -e "\033[0;31mUsers:\033[0m"
ipa user-find #Returns all users
ipa user-find|grep "User login: " |awk '{print $NF}' > idm_users.txt #Outputs just usernames to idm_users.txt
echo -e "\033[0;32mGroups:\033[0m"
ipa group-find #Returns group names, descriptions and GIDs
ipa group-find | grep "Group name:" | awk '{print $NF}' > idm_groups.txt #Outputs just group names to a file
echo "Users saved in idm_users.txt, groups saved in idm_groups.txt"