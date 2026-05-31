#!/bin/bash

wireguard_baremetal_deployment(){
    # Wireguard setup
    if ! command -v "wireguard" &> /dev/null; then
        echo "Needs to install wireguard."
        return 0
    fi

    # Enable packet forwarding  
    sudo sed 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sudo sysctl -p /etc/sysctl.conf
}