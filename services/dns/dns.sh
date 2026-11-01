#!/bin/bash

DNS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$DNS_SERVICE_FOLDER/../../lib/backup.sh"
source "$DNS_SERVICE_FOLDER/pihole/pihole.sh"

dns_deploy(){
    pihole_deploy_docker
}

dns_stop(){
    pihole_stop_docker
}

dns_clean(){
    pihole_clean_docker
}

dns_backup(){
    pihole_backup_docker
}

dns_restore(){
    pihole_restore_backup_docker "$1"
}

dns_update(){
    pihole_update_docker
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
	backup)
		dns_backup
		;;
	restore)
		dns_restore "$2"
		;;
	update)
		dns_update
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore|update]" >&2
		exit 1
		;;
esac
