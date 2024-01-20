#!/bin/bash

###################################################################
# Installs snoopy for Debian-based systems
# Attended install
# By Guac0
###################################################################

echo "Installing Snoopy for Debian-based systems..."
apt update
apt install snoopy -y
echo "Snoopy has been installed!"
echo "It is recommended to reboot this machine to get the full effect."