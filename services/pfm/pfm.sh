#!/bin/bash

PFM_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$PFM_SERVICE_FOLDER/fireflyiii/fireflyiii.sh"

pfm_deploy(){
    personal_finance_manager_deploy_docker
}

pfm_stop(){
    personal_finance_manager_stop_docker
}

pfm_clean(){
    personal_finance_manager_clean_docker
}

pfm_backup(){
    echo "TODO: implement PFM backup"
}

pfm_restore(){
    echo "TODO: implement PFM restore"
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
		pfm_restore
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore]" >&2
		exit 1
		;;
esac
