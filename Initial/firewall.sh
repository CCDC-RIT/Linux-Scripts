#!/bin/bash

## May Have to mess around with firewalld ## 
    # sudo systemctl stop firewalld
    # sudo sysytemctl disable firewalld\


######################
# Allows specific services, blocks all others, includes anti-lockout
# Intended to be manually edited according to box
# Updated by Guac.0
######################

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
# NAT and RAW tables too? sure, why not
echo "> Flushing Tables"
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X
iptables -t nat -F
iptables -t nat -X
iptables -F
iptables -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -t raw -F
ip6tables -t raw -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -F
ip6tables -X

## Keep default policy to ALLOW and just add a deny at the end
## This is sorta meh (if red team drops the deny then its all allowed/if new rule is added after then it wont have affect)
## but it prevents red from doing an iptables funny

## dawg what is the snat and dnat states, im not gonna worry about that

## Allow ICMP 
echo "> Allow ICMP"
iptables -t mangle -A INPUT -p ICMP -j ACCEPT
iptables -t mangle -A OUTPUT -p ICMP -j ACCEPT

## Allow Loopback Traffic
echo "> Allow Loopback Traffic"
iptables -t mangle -A INPUT -i lo -j ACCEPT
iptables -t mangle -A OUTPUT -o lo -j ACCEPT

## Allow all ESTABLISHED and RELATED. This means we just need to allow NEW connections for each specific rule
echo "> Allow all established and related traffic"
iptables -t mangle -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t mangle -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

## Allow Incoming SSH
echo "> Allow Inbound SSH"
iptables -t mangle -A INPUT -p tcp -m multiport --dports 22 -m state --state NEW -j ACCEPT

## Allow Client to Server Outbound Hashicorp Vault (add this on all clients, not the vault)
echo "> Allow Outbound Hashicorp Vault for Client to Server Comms"
iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 8200,443 -m state --state NEW -j ACCEPT

## Allow Scored Service outbound (CCSClient)
#iptables -t mangle -A OUTPUT -p tcp -d scoring_ip -m multiport --dports 80,443 -m state --state NEW -j ACCEPT
#iptables -t mangle -A INPUT -p tcp -d scoring_ip -m multiport --sports 80,443 -m state --state NEW -j ACCEPT #is incoming connections from server a thing?



########################
# OTHER OPTIONAL RULES #
########################

# # Iptables Ranges
# iptables -t mangle -A INPUT -s 10.5.1.0/24 -j ACCEPT
# iptables -t mangle -A INPUT -s 10.5.2.0/24 -j ACCEPT
# iptables -t mangle -A INPUT -s 10.x.x.0/24 -j DROP
# iptables -t mangle -A OUTPUT -s 10.x.x.0/24 -j DROP
# iptables -t mangle -A INPUT -s 10.2.3.4 -j DROP

# # Allow HTTP Outgoing for Clients
# echo "> Allow Outbound HTTP for Clients"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80 -m state --state NEW -j ACCEPT

# # Allow HTTP Incoming for Servers
# echo "> Allow Inbound HTTP for Servers"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 80 -m state --state NEW -j ACCEPT

# # Allow HTTPS Outgoing for Clients
# echo "> Allow Outbound HTTPS for Clients"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 443 -m state --state NEW -j ACCEPT

# # Allow HTTPS Incoming for Servers
# echo "> Allow Inbound HTTPS for Servers"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 443 -m state --state NEW -j ACCEPT

# # Allow DNS Outgoing (UDP) for Client
# echo "> Allow Outbound DNS (UDP) for Client"
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 53 -m state --state NEW -j ACCEPT

# # Allow DNS Incoming (UDP) for Server
# echo "> Allow Inbound DNS (UDP) for Server"
# iptables -t mangle -A INPUT -p udp -m multiport --dports 53 -m state --state NEW -j ACCEPT

# # Allow SSH Outgoing
# echo "> Allow Outbound SSH"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 22 -m state --state NEW -j ACCEPT

# # Allow MariaDB/MySQL Outgoing
# echo "> Allow Outbound MariaDB/MySQL for Client"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 3306 -m state --state NEW -j ACCEPT

# # Allow MariaDB/MySQL Incoming for Server
# echo "> Allow Inbound MariaDB/MySQL for Server"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 3306 -m state --state NEW -j ACCEPT

# # Allow Postgresql Outgoing for Client to Server
# echo "> Allow Outbound Postgresql for Client"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 5432 -m state --state NEW -j ACCEPT

# # Allow Postgresql Incoming for Server
# echo "> Allow Inbound Postgresqlfor Server"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 5432 -m state --state NEW -j ACCEPT

# # Allow Wazuh Bidirectional
# echo "> Allow Wazuh Bidirectional"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state NEW -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 514,1514 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 443,514,1514,1515,1516,9200,9300:9400,55000 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p udp -m multiport --dports 514,1514 -m state --state NEW -j ACCEPT

# # Allow RHEL IDM clients Outbound
# echo "> Allow RHEL IDM Clients Outbound"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80,443,389,636,88,464,53,749 -m state --state NEW -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 88,464,53,123 -m state --state NEW -j ACCEPT

# # Allow RHEL IDM clients Inbound
# # Server *shouldn't* be initiating connections... probably. This is here just in case.
# echo "> Allow RHEL IDM Clients Inbound"
# iptables -t mangle -A INPUT -p tcp -m multiport --sports 80,443,389,636,88,464,53,749 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p udp -m multiport --sports 88,464,53,123 -m state --state NEW -j ACCEPT

# # Allow RHEL IDM server-server comms
# # Probably not needed if you just have a single server...
# echo "> Allow RHEL IDM Server to Server (udp)"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80,443,389,636,88,464,53,749,7389,9443,9444,9445,8005,8009 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p tcp -m multiport --sports 80,443,389,636,88,464,53,749,7389,9443,9444,9445,8005,8009 -m state --state NEW -j ACCEPT
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 88,464,53,123 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p udp -m multiport --sports 88,464,53,123 -m state --state NEW -j ACCEPT

# # Allow Hashicorp Vault Bidirectional for Server to Server Comms
# 443 is client to load balancer, 8200 incoming is between load balancer and servers, rest are server to server (or server to external api but those vary)
# echo "> Allow Bidirectional Hashicorp Vault for Server to Server Comms"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 8200,8201 -m state --state NEW -j ACCEPT
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 8200,8201 -m state --state NEW -j ACCEPT

# # Allow Hashicorp Vault Load Balancer/Server Incoming
# echo "> Allow Inbound Hashicorp Vault for Load Balancer/Server"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 8200,443 -m state --state NEW -j ACCEPT

# # Allow Kubernetes Control Plane
# echo "> Allow Kubernetes Control Plane"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 6443,2379,2380,10250,10259,10257 -m state --state NEW -j ACCEPT
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 10250,30000:32767 -m state --state NEW -j ACCEPT

# # Allow Kubernetes Worker Node
# echo "> Allow Kubernetes Worker Node"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 10250,30000:32767 -m state --state NEW -j ACCEPT
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 6443,2379,2380,10250,10259,10257 -m state --state NEW -j ACCEPT

# # Allow Gitlab Server Incoming
# # 5050 is also needed for remote access to container registry but that's (mostly?) optional, plus any additional services
# echo "> Allow Gitlab Server Incoming"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

# # Allow Gitlab Client Outbound
# # 5050 is also needed for remote access to container registry but that's (mostly?) optional, plus any additional services
# echo "> Allow Gitlab Client Outbound"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

# # Allow Syslog Outbound (for clients)
# echo "> Allow Syslog (for clients) Outbound"
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 514 -m state --state NEW -j ACCEPT

# # Allow Syslog Inbound (for server)
# echo "> Allow Syslog (for server) Inbound"
# iptables -t mangle -A INPUT -p udp -m multiport --dports 514 -m state --state NEW -j ACCEPT

# # Allow Argus Inbound (for server)
# echo "> Allow Argus Inbound (for server)"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 561 -m state --state NEW -j ACCEPT

# # Allow Argus Outbound (for client)
# echo "> Allow Argus Outbound (for client)"
# iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 561 -m state --state NEW -j ACCEPT

# # Accept Various Port(s) Incoming
# echo "> Various Port(s) Incoming"
# iptables -t mangle -A INPUT -p tcp -m multiport --dports 100,101 -m state --state NEW -j ACCEPT

# # Allow Various Port(s) Outgoing
# echo "> Various Port(s) Outgoing"
# iptables -t mangle -A OUTPUT -p udp -m multiport --dports 100,101 -m state --state NEW -j ACCEPT


##################
## Ending Rules ##
##################

# # Drop All Traffic If Not Matching
# # Don't add new rules after this!
# # TODO also change default policy to drop... maybe
echo "> Drop non-matching traffic : Connection may drop"
iptables -t mangle -A INPUT -j DROP
iptables -t mangle -A OUTPUT -j DROP

## IPv6 is cringe, drop all of that
## DONT RUN THIS ON RHEL IDM PLEASE PLEASE PLEASE
echo "> Drop all IPv6 traffic : Connection may drop"
echo "> If you're on IPv6, skill issue. just NAT it more lmao"
ip6tables -t mangle -P INPUT DROP
ip6tables -t mangle -P OUTPUT DROP

# Backup Rules (iptables -t mangle-restore < backup)
echo "> Backing up rules"
iptables-save > /etc/ip_rules
ip6tables-save > /etc/ip6_rules

# Anti-Lockout Rule
# If user gets locked out by the drop all, then this will run and cancel the changes
echo "> Sleep Initiated : Cancel Program to prevent flush"
echo "> pssst: this means to cancel the program to save the firewall changes"
sleep 5
iptables -t mangle -F
echo "> Anti-Lockout executed : Rules have been flushed"
