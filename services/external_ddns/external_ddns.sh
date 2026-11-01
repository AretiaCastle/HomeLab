#!/bin/bash

EXTERNAL_DDNS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$EXTERNAL_DDNS_SERVICE_FOLDER/duckdns/duckdns.sh"

external_ddns_deploy(){
	duckdns_deploy_docker
}

external_ddns_stop(){
	duckdns_stop_docker
}

external_ddns_clean(){
	duckdns_clean_docker
}

# Duck DNS has no persistent data, its configuration is the env file
external_ddns_backup(){
	echo "External DDNS has no data to back up, skipping backup"
}

external_ddns_restore(){
	echo "External DDNS has no data to restore, skipping restore"
}

external_ddns_update(){
	duckdns_update_docker
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
		external_ddns_restore "$2"
		;;
	update)
		external_ddns_update
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore|update]" >&2
		exit 1
		;;
esac
