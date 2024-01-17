#!/bin/bash
ipa user-find|grep "User login: " |awk '{print $NF}' > idm_users.txt
echo "Users saved in idm_users.txt"