I wanted a way to reload the config files on my High Availibility Kea DHCP servers (I'm using hot/standby redundancy and Kea version 2.4.1) without restarting the kea systemd service. So I created this script to test the config files 
on both systems, compare the configs (they should be pretty much the same except the HA config) and then reload the config on the backup server and then the primary. This also checks the state of the backup 
server before running the reload on the primary server and then waits for the HA status to be restored before exiting.

How to use:
1. Update the variables (replace what is in the "")on lines 3 through 8 with your info:
```
     haserver1="Primary-Server-Name"
     haserver1ip="PrimaryServerIP"
     haserver2="Backup-Server-Name"
     haserver2ip="BackupServerIP"
     keadhcp4config="/etc/kea/kea-dhcp4.conf" ##this is the location of the config file on the servers. This is the default location for Rocky Linux
     pem="~/.ssh/id_rsa"
```   
>[!NOTE]
>*If you are using an alternate port then 8001 for the Kea Control Agent. You can get this port in the kea-ctrl-agent.conf file under "http-port": <port number>, go into the script and replace all instances of 8001

>[!NOTE]
>**It uses SSH public keys to log in to check the config files on both servers. In my case the servers are clones so they use the same public key to login. If they are different for you, 
>you will have to get both PEM files and update the ssh variables.

2. Login and update config files (/etc/kea/kea-dhcp4.conf) on both primary and backup servers. 

3. run script ./dhcp_config_update.sh

