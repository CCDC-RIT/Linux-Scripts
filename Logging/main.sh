# rewrite old installation
./manager-wazuh-unattended-installation.sh -a -i -o 

# change passwords
curl -so wazuh-passwords-tool.sh https://packages.wazuh.com/4.5/wazuh-passwords-tool.sh
bash wazuh-passwords-tool.sh -a > /opt/wazuhpw.txt # temporary file name - change later

# file permissions
chmod /var/ossec/etc/ossec.conf 660
chmod /var/ossec/etc/shared/default/agent.conf 660
chmod -R /var/ossec/etc/rules/ 660
chmod /var/ossec/etc/internal_options.conf 640
chmod /var/ossec/logs/ossec.conf 660
