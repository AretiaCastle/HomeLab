#!/bin/bash

VPN_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$VPN_SERVICE_FOLDER/../../lib/backup.sh"
source "$VPN_SERVICE_FOLDER/wgdashboard/wgdashboard.sh"

vpn_deploy(){
	wgdashboard_deploy_docker
}

vpn_stop(){
	wgdashboard_stop_docker
}

vpn_clean(){
	wgdashboard_clean_docker
}

vpn_backup(){
	wgdashboard_backup_docker
}

vpn_restore(){
	wgdashboard_restore_docker "$1"
}

vpn_update(){
	wgdashboard_update_docker
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
	backup)
		vpn_backup
		;;
	restore)
		vpn_restore "$2"
		;;
	update)
		vpn_update
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore|update]" >&2
		exit 1
		;;
esac
