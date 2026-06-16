#!/bin/bash

wireguard_baremetal_deployment(){
    # Wireguard setup
    if ! command -v "wg" &> /dev/null; then
        echo "Needs to install wireguard."
        sudo apt install -y wireguard
    fi

    # Enable packet IPv4 packets forwarding  
    echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-wireguard-forward.conf >/dev/null
    sudo sysctl --system
}
