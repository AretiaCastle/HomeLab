#!/bin/bash

VPN_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$VPN_SERVICE_FOLDER/wireguard/wireguard.sh"
source "$VPN_SERVICE_FOLDER/wgdashboard/wgdashboard.sh"

vpn_deploy(){
	wireguard_baremetal_deployment
	wgdashboard_baremetal_deployment
}

vpn_stop(){
    wireguard_stop
    wgdashboard_stop
}

vpn_clean(){
    wireguard_clean
    wgdashboard_clean
}

action="${1:-deploy}"

case "$action" in
	deploy)
		vpn_deploy
		;;
	stop)
		vpn_stop
		;;
	clean)
		vpn_clean
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean]" >&2
		exit 1
		;;
esac
