#!/bin/bash
echo -e "\033[0;31mUsers:\033[0m"
ipa user-find #Returns all users
ipa user-find > idm-users.txt #Repeats this command but echoes the output to a file 
echo -e "\033[0;32mGroups:\033[0m"
ipa group-find #Returns group names, descriptions and GIDs
ipa group-find #Repeats this command but echoes the output to a file
