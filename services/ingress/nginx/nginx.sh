#!/bin/bash

NGINX_PROXY_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
NGINX_PROXY_COMPOSE_PROJECT="${PROJECT}-nginx"

nginx_proxy_deployment_docker(){
    mkdir -p "$NGINX_PROXY_DATA_PATH"
    mkdir -p "$NGINX_PROXY_LETSENCRYPT_PATH"

    docker compose -p "$NGINX_PROXY_COMPOSE_PROJECT" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" up -d
}

nginx_proxy_stop_docker(){
    docker compose \
        -p "$NGINX_PROXY_COMPOSE_PROJECT" \
        -f "$NGINX_PROXY_FOLDER/docker-compose.yml" \
        stop
}

nginx_proxy_cleanup_docker(){
    docker compose \
        -p "$NGINX_PROXY_COMPOSE_PROJECT" \
        -f "$NGINX_PROXY_FOLDER/docker-compose.yml" \
        down --volumes
}

nginx_proxy_backup_docker(){
    if ! docker_project_deployed "$NGINX_PROXY_COMPOSE_PROJECT"; then
        echo "Nginx Proxy Manager is not deployed, skipping backup"
        return 0
    fi

    docker_volumes_backup "$NGINX_PROXY_COMPOSE_PROJECT" "$NGINX_PROXY_BASE_VOLUMES_PATH" "$NGINX_PROXY_BACKUP_PATH" || exit 1
}

# $1 Backup file name (optional, newest volumes backup by default)
nginx_proxy_restore_docker(){
    docker_restore "$NGINX_PROXY_COMPOSE_PROJECT" "$NGINX_PROXY_BASE_VOLUMES_PATH" "$NGINX_PROXY_BACKUP_PATH" "$1" || exit 1
}
