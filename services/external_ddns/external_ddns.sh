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

external_ddns_backup(){
    echo "TODO: implement External DDNS backup"
}

external_ddns_restore(){
    echo "TODO: implement External DDNS restore"
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
	backup)
		external_ddns_backup
		;;
	restore)
		external_ddns_restore
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore]" >&2
		exit 1
		;;
esac
