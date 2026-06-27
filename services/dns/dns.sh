#!/bin/bash

DNS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$DNS_SERVICE_FOLDER/pihole/pihole.sh"

dns_deploy(){
	pihole_baremetal_deployment
}

dns_stop(){
	echo "TODO: implement DNS stop"
}

dns_clean(){
	echo "TODO: implement DNS clean"
}

action="${1:-deploy}"

case "$action" in
	deploy)
		dns_deploy
		;;
	stop)
		dns_stop
		;;
	clean)
		dns_clean
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean]" >&2
		exit 1
		;;
esac
