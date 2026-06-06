#!/bin/bash

wgdashboard_baremetal_deployment(){
    #WGDashboard setup
    sudo apt install git iptables wireguard-tools net-tools && \
    sudo apt update && \
    git clone https://github.com/donaldzou/WGDashboard.git && \
    chmod +x ./WGDashboard/src/wgd.sh && \
    sudo mv ./WGDashboard /usr/local/bin/ && \
    cd /usr/local/bin/WGDashboard/src && \
    ./wgd.sh install && \
    cd
}