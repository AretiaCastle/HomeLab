#!/bin/bash

INGRESS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$INGRESS_SERVICE_FOLDER/../../lib/backup.sh"
source "$INGRESS_SERVICE_FOLDER/nginx/nginx.sh"

ingress_deploy(){
	nginx_proxy_deployment_docker
}

ingress_stop(){
	nginx_proxy_stop_docker
}

ingress_clean(){
	nginx_proxy_cleanup_docker
}

ingress_backup(){
	nginx_proxy_backup_docker
}

ingress_restore(){
	nginx_proxy_restore_docker "$1"
}

ingress_update(){
	nginx_proxy_update_docker
}

action="${1:-deploy}"

case "$action" in
	deploy)
		ingress_deploy
		;;
	stop)
		ingress_stop
		;;
	clean)
		ingress_clean
		;;
	backup)
		ingress_backup
		;;
	restore)
		ingress_restore "$2"
		;;
	update)
		ingress_update
		;;
	*)
		echo "Usage: $0 [deploy|stop|clean|backup|restore|update]" >&2
		exit 1
		;;
esac
