#!/bin/bash

INGRESS_SERVICE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
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
	*)
		echo "Usage: $0 [deploy|stop|clean]" >&2
		exit 1
		;;
esac
