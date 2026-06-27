#!/bin/bash

NGINX_PROXY_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

nginx_proxy_deployment_docker(){
    mkdir -p "$NGINX_PROXY_MAIN_VOLUME_PATH"
    mkdir -p "$NGINX_PROXY_DATA_VOLUME_PATH"
    mkdir -p "$NGINX_PROXY_LETSENCRYPT_VOLUME_PATH"

    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" up -d
}

nginx_proxy_stop_docker(){
    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" stop
}

nginx_proxy_cleanup_docker(){
    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" down --remove-orphans --volumes
}
