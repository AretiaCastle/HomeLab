#!/bin/bash

VPN_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "$VPN_SERVICE_FOLDER/wireguard/wireguard.sh"
wireguard_baremetal_deployment

source "$VPN_SERVICE_FOLDER/wgdashboard/wgdashboard.sh"
wgdashboard_baremetal_deployment
