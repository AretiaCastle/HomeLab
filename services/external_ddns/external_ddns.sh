#!/bin/bash

EXTERNAL_DDNS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$EXTERNAL_DDNS_SERVICE_FOLDER/duckdns/duckdns.sh"

external_ddns_deploy(){
	duck_dns_configuration
}

external_ddns_stop(){
    duck_dns_stop
}

external_ddns_clean(){
    duck_dns_clean
}

action="${1:-deploy}"

case "$action" in
	deploy)
		external_ddns_deploy
		;;
	stop)
		external_ddns_stop
		;;
	clean)
		external_ddns_clean
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean]" >&2
		exit 1
		;;
esac
