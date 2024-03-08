#!/bin/bash

haserver1="Primary-Server-Name"
haserver1ip="PrimaryServerIP"
haserver2="Backup-Server-Name"
haserver2ip="BackupServerIP"
keadhcp4config="/etc/kea/kea-dhcp4.conf"
pem="~/.ssh/id_rsa"
haconfig1=$(ssh -i $pem root@"$haserver1ip" "cat $keadhcp4config" | jq)
haconfig2=$(ssh -i $pem root@"$haserver2ip" "cat $keadhcp4config" | jq)
counter1=0
counter2=0

clear
echo
echo "Testing dhcp4 configuration $keadhcp4config for $haserver1:"
echo
ssh -i $pem root@"$haserver1ip" "kea-dhcp4 -T $keadhcp4config | grep -v 'INFO'"
echo

echo
echo "Testing dhcp4 configuration $keadhcp4config for $haserver2:"
echo
ssh -i $pem root@"$haserver2ip" "kea-dhcp4 -T $keadhcp4config | grep -v 'INFO'"
echo

echo "Checking configuration on $haserver1 and $haserver2 for differences:"
echo


if diff -I 'this-server-name\|hash' <(echo "$haconfig1") <(echo "$haconfig2") &> /dev/null; then
    echo "Successful: Configuration $keadhcp4config is the same on $haserver1 and $haserver2."
else
    echo "Error: Configuration $keadhcp4config has differences."
    echo "Check the $keadhcp4config file on $haserver2 to ensure it has been updated the same as $haserver1 and try again."
    exit 1
fi

echo
read -p "With the results above do you want to continue on to reloading the configurations? (y/n): " choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo
    echo "Reloading Configuration on $haserver2"
    echo
    echo
    reload2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "config-reload", "service": [ "dhcp4" ]}' "http://$haserver2ip:8001/" | jq -r '.[].text')
      if [[ "$reload2" != *"successful"* ]]; then
        echo "Error: Configuration reload on $haserver2 failed. Aborting."
        exit 1
    fi
    echo
    echo "Checking $haserver2 state:"
    sleep 1
    while true; do
        response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "status-get", "service": [ "dhcp4" ]}' "http://$haserver2ip:8001/" | jq -r '.[0].arguments."high-availability"[0]."ha-servers"."local"."state"')
        if [[ "$response" == "hot-standby" ]]; then
            echo "              Current status for $haserver2: $response"
            echo
            role2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "status-get", "service": [ "dhcp4" ]}' "http://$haserver2ip:8001/" | jq -r '.[0].arguments."high-availability"[0]."ha-servers"."local"."role"')
            echo "Configuration reload completed successfully for $haserver2. Current role: $role2"
            echo
            echo
            break
        else
            echo "              Current status for $haserver2: $response"
            sleep 1
        fi
        ((counter1++))
        if ((counter1 >= 20)); then
            echo "ERROR: $haserver2 state has not changed back to hot-standby. Exiting..."
            exit 1
        fi
    done

read -p "Would you like to continue to reload the configuration on $haserver1? (y/n): " choice
if [[ "$choice" =~ ^[Nn]$ ]]; then
    echo
    echo "Canceling..."
    echo
    exit 1
elif [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo
    echo "Invalid choice. Please enter 'y' or 'n'."
    echo
    exit 1
fi


    echo
    echo "Reloading Configuration on $haserver1"
    echo
    echo
    response2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "config-reload", "service": [ "dhcp4" ]}' "http://$haserver1ip:8001/" | jq -r '.[].text')
    if [[ "$response2" != *"successful"* ]]; then
        echo "Error: Configuration reload on $haserver1 failed. Aborting."
        exit 1
    fi
    echo
    echo "Checking $haserver1 state:"
    sleep 1
    while true; do
        response1=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "status-get", "service": [ "dhcp4" ]}' "http://$haserver1ip:8001/" | jq -r '.[0].arguments."high-availability"[0]."ha-servers"."local"."state"')
        if [[ "$response1" == "hot-standby" ]]; then
            echo "              Current status for $haserver1: $response1"
            echo
            role1=$(curl -s -X POST -H "Content-Type: application/json" -d '{"command": "status-get", "service": [ "dhcp4" ]}' "http://$haserver1ip:8001/" | jq -r '.[0].arguments."high-availability"[0]."ha-servers"."local"."role"')
            echo "Configuration reload completed successfully for $haserver1. Current role: $role1"
            echo
            echo
            break
        else
            echo "              Current status for $haserver1: $response1"
            sleep 1
        fi
        ((counter2++))
        if ((counter2 >= 20)); then
            echo "ERROR: $haserver1 state has not changed back to hot-standby. Exiting..."
            exit 1
        fi
    done

elif [[ "$choice" =~ ^[Nn]$ ]]; then
    echo
    echo "Canceling..."
    echo
    exit 1
else
    echo
    echo "Invalid choice. Please enter 'y' or 'n'."
    echo
    exit 1
fi
