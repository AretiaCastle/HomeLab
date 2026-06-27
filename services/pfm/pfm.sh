#!/bin/bash

PFM_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$PFM_SERVICE_FOLDER/firefly_iii/firefly_iii.sh"

pfm_deploy(){
	echo "TODO: implement Personal Finance Manager deploy"
}

pfm_stop(){
	echo "TODO: implement Personal Finance Manager stop"
}

pfm_clean(){
	echo "TODO: implement Personal Finance Manager clean"
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
	*)
		echo "Usage: $0 [deploy|stop|clean]" >&2
		exit 1
		;;
esac
