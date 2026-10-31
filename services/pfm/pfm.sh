#!/bin/bash

PFM_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$PFM_SERVICE_FOLDER/../../lib/backup.sh"
source "$PFM_SERVICE_FOLDER/fireflyiii/fireflyiii.sh"

pfm_deploy(){
    fireflyiii_deploy_docker
}

pfm_stop(){
    fireflyiii_stop_docker
}

pfm_clean(){
    fireflyiii_clean_docker
}

pfm_backup(){
    fireflyiii_backup_docker
}

pfm_restore(){
    fireflyiii_restore_backup_docker "$1"
}

action="${1:-deploy}"

case "$action" in
	deploy)
		pfm_deploy
		;;
	stop)
		pfm_stop
		;;
	clean)
		pfm_clean
		;;
	backup)
		pfm_backup
		;;
	restore)
		pfm_restore "$2"
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore]" >&2
		exit 1
		;;
esac
