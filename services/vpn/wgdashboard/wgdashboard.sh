#!/bin/bash

wgdashboard_baremetal_deployment(){
    #WGDashboard setup
    sudo apt install git iptables wireguard-tools net-tools && \
    sudo apt update && \
    git clone https://github.com/donaldzou/WGDashboard.git "$DEPLOYMENTS_BASE_PATH/WGDashboard"
    
    chmod +x "$DEPLOYMENTS_BASE_PATH/WGDashboard/src/wgd.sh"
    cd "$DEPLOYMENTS_BASE_PATH/WGDashboard/src" && ./wgd.sh install

    # Start the service
    cd "$DEPLOYMENTS_BASE_PATH/WGDashboard/src" && ./wgd.sh start
}

# TODO 
wgdashboard_docker_deployment(){
    echo "WIP"
}