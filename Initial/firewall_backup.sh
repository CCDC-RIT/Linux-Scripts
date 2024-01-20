#!/bin/bash

## May Have to mess around with firewalld ## 
    # sudo systemctl stop firewalld
    # sudo sysytemctl disable firewalld

# If this Script is not Working check .bashrc or aliases

###########################
## Must run as superuser ##
###########################

if [ "$EUID" -ne 0 ]
  then echo "Must run as superuser"
  exit
fi

# Import inventory script for service variables, redirect output to null
# source inventory.sh > /dev/null 2>&1

################
## Main Rules ##
################

# Flush Tables
# Might also need to drop the NAT and RAW tables...
echo "> Flushing Tables"
iptables -t mangle -F
iptables -t mangle -X
iptables -F
iptables -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -F
ip6tables -X

# IPv6 is cringe
ip6tables -t mangle -P INPUT DROP
ip6tables -t mangle -P OUTPUT DROP

# Accept by default in case of flush
echo "> Applying Default Accept"
iptables -t mangle -P INPUT ACCEPT
iptables -t mangle -P OUTPUT ACCEPT

# Allow ICMP 
echo "> Allow ICMP"
iptables -t mangle -A INPUT -p ICMP -j ACCEPT
iptables -t mangle -A OUTPUT -p ICMP -j ACCEPT

# Allow Loopback Traffic
echo "> Allow Loopback Traffic"
iptables -t mangle -A INPUT -i lo -j ACCEPT
iptables -t mangle -A OUTPUT -o lo -j ACCEPT

# Allow Incoming SSH
echo "> Allow Inbound SSH"
iptables -t mangle -A INPUT -p tcp --dport ssh -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t mangle -A OUTPUT -p tcp --sport ssh -m state --state ESTABLISHED -j ACCEPT

## Allow Scored Service outbound (CCSClient)
#iptables -t mangle -A OUTPUT -p tcp -d scoring_ip --dport 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -t mangle -A INPUT -p tcp -d scoring_ip --dport 80,443 -m state --state ESTABLISHED -j ACCEPT



########################
# OTHER OPTIONAL RULES #
########################

# # Iptables Ranges
# iptables -t mangle -A INPUT -s 10.5.1.0/24 -j ACCEPT
# iptables -t mangle -A INPUT -s 10.5.2.0/24 -j ACCEPT
# iptables -t mangle -A INPUT -s 10.x.x.0/24 -j DROP
# iptables -t mangle -A OUTPUT -s 10.x.x.0/24 -j DROP
# iptables -t mangle -A INPUT -s 10.2.3.4 -j DROP

# # Allow HTTP Outgoing
# echo "> Allow Outbound HTTP"
# iptables -t mangle -A OUTPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# # Allow HTTP Incoming
# echo "> Allow Inbound HTTP"
# iptables -t mangle -A INPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# # Allow DNS Outgoing (UDP)
# echo "> Allow Outbound DNS (UDP)"
# iptables -t mangle -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT  -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

# # Allow DNS Incoming (UDP)
# echo "> Allow Inbound DNS (UDP)"
# iptables -t mangle -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT

# # Allow SSH Outgoing
# echo "> Allow Outbound SSH"
# iptables -t mangle -A OUTPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# # Allow MariaDB/MySQL Outgoing
# echo "> Allow Outbound MariaDB/MySQL"
# iptables -t mangle -A OUTPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

# # Allow MariaDB/MySQL Incoming
# echo "> Allow Inbound MariaDB/MySQL"
# iptables -t mangle -A OUTPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

# # Allow Postgresql Outgoing
# echo "> Allow Outbound Postgresql "
# iptables -t mangle -A OUTPUT -p tcp --dport 5432 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 5432 -m state --state ESTABLISHED -j ACCEPT

# # Allow Postgresql Incoming
# echo "> Allow Inbound Postgresql"
# iptables -t mangle -A OUTPUT -p tcp --dport 5432 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 5432 -m state --state ESTABLISHED -j ACCEPT

# # Allow Wazuh Outgoing
# echo "> Allow Outbound Wazuh "
# iptables -t mangle -A OUTPUT -p tcp --dport 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp --dport 514,1514 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p udp --sport 514,1514 -m state --state ESTABLISHED -j ACCEPT

# # Allow Wazuh Incoming
# echo "> Allow Inbound Wazuh"
# iptables -t mangle -A OUTPUT -p tcp --dport 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp --dport 514,1514 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p udp --sport 514,1514 -m state --state ESTABLISHED -j ACCEPT

# # Allow RHEL IDM clients Outbound
# # Server *shouldn't* be initiating connections... probably. Just change "ESTABLISHED" to "NEW,ESTABLISHED" for INPUT if server initiates
# echo "> Allow RHEL IDM Clients Outbound"
# iptables -t mangle -A OUTPUT -p tcp --dport 80,443,389,636,88,464,53,749 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 80,443,389,636,88,464,53,749 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp --dport 88,464,53,123 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p udp --sport 88,464,53,123 -m state --state ESTABLISHED -j ACCEPT

# # Allow RHEL IDM server-server comms
# # Probably not needed if you just have a single server...
# echo "> Allow RHEL IDM Server to Server (udp)"
# iptables -t mangle -A OUTPUT -p tcp --dport 80,443,389,636,88,464,53,749,7389,9443,9444,9445,8005,8009 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 80,443,389,636,88,464,53,749,7389,9443,9444,9445,8005,8009 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp --dport 88,464,53,123 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p udp --sport 88,464,53,123 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Allow Hashicorp Vault Bidirectional
# 443 is client to load balancer, 8200 incoming is between load balancer and servers, rest are server to server (or server to external api but those vary)
# echo "> Allow Bidirectional Hashicorp Vault"
# iptables -t mangle -A OUTPUT -p tcp --dport 8200,8201 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 8200,8201 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Allow Hashicorp Vault Incoming
# echo "> Allow Inbound Hashicorp Vault"
# iptables -t mangle -A OUTPUT -p tcp --dport 8200,443 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 8200,443 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Allow Kubernetes Control Plane Incoming
# echo "> Allow Kubernetes Control Plane Incoming"
# iptables -t mangle -A OUTPUT -p tcp --dport 6443,2379,2380,10250,10259,10257 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 6443,2379,2380,10250,10259,10257 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Allow Kubernetes Worker Node Incoming
# echo "> Allow Kubernetes Control Plane Incoming"
# iptables -t mangle -A OUTPUT -p tcp --dport 10250,30000:32767 -m state --state ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 10250,30000:32767 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Allow Gitlab Bidirectional (not sure which direction we need...)
# 5050 is also needed for remote access to container registry but that's (mostly?) optional, plus any additional services
# echo "> Allow Gitlab Bidirectional"
# iptables -t mangle -A OUTPUT -p tcp --dport 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT -p tcp --sport 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT

# # Accept Various Port Incoming
# echo "> Various Port Incoming"
# iptables -t mangle -A INPUT -p tcp --dport 8000 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A OUTPUT -p tcp --sport 8000 -m state --state ESTABLISHED -j ACCEPT

# # Allow Various Port Outgoing
# echo "> Various Port Outgoing"
# iptables -t mangle -A OUTPUT -p udp --dport 3000 -m state --state NEW,ESTABLISHED -j ACCEPT
# iptables -t mangle -A INPUT  -p udp --sport 3000 -m state --state ESTABLISHED -j ACCEPT


##################
## Ending Rules ##
##################

# Drop All Traffic If Not Matching
echo "> Drop non-matching traffic : Connection may drop"
iptables -t mangle -A INPUT -j DROP
iptables -t mangle -A OUTPUT -j DROP

# Backup Rules (iptables -t mangle-restore < backup)
echo "> Backing up rules"
iptables-save >/etc/ip_rules

# Anti-Lockout Rule
# If user gets locked out by the drop all, then this will run and cancel the changes
echo "> Sleep Initiated : Cancel Program to prevent flush"
echo "> pssst: this means to cancel the program to save the firewall changes"
sleep 5
iptables -t mangle -F
echo "> Anti-Lockout executed : Rules have been flushed"
