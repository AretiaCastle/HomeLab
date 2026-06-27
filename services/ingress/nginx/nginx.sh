#!/bin/bash

NGINX_PROXY_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

nginx_proxy_deployment_docker(){
    mkdir -p "$NGINX_PROXY_DATA_VOLUME_PATH"
    mkdir -p "$NGINX_PROXY_LETSENCRYPT_VOLUME_PATH"

    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" up -d

    # Automated backup
    mkdir -p "$NGINX_PROXY_BACKUP_PATH"

    # Backup every day at 03:30 and 04:00
    cron_header="# Nginx proxy manager backup tasks"
    cron_nginx_data="30 03     * * *   root    cp -r $NGINX_PROXY_DATA_VOLUME_PATH $NGINX_PROXY_BACKUP_PATH"
    cron_letsencrypt="00 04     * * *   root    cp -r $NGINX_PROXY_LETSENCRYPT_VOLUME_PATH $NGINX_PROXY_BACKUP_PATH"

    if ! sudo grep -Fqx "$cron_header" "$CRON_FILEPATHPATH"; then
        echo "$cron_header" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_nginx_data" "$CRON_FILEPATH"; then
        echo "$cron_nginx_data" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_letsencrypt" "$CRON_FILEPATH"; then
        echo "$cron_letsencrypt" | sudo tee -a "$CRON_FILEPATH" > /dev/null
    fi
}

nginx_proxy_stop_docker(){
    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" stop
}

nginx_proxy_cleanup_docker(){
    docker compose -p "${PROJECT}" -f "$NGINX_PROXY_FOLDER/docker-compose.yml" down --remove-orphans --volumes
}
