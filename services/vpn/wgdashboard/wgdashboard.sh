#!/bin/bash

WGDASHBOARD_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
WGDASHBOARD_COMPOSE_PROJECT="${PROJECT}-wgdashboard"
WGDASHBOARD_ENV_FILE="$WGDASHBOARD_FOLDER/.env.wgdashboard"

check_wgdashboard_env_files(){
    if [[ ! -f "$WGDASHBOARD_ENV_FILE" ]]; then
        echo "ERROR: missing file $WGDASHBOARD_ENV_FILE" >&2
        return 1
    fi

    return 0
}

wgdashboard_deploy_docker(){
    check_wgdashboard_env_files || exit 1

    mkdir -p "$WGDASHBOARD_ACONF_VOLUME_PATH"
    mkdir -p "$WGDASHBOARD_CONF_VOLUME_PATH"
    mkdir -p "$WGDASHBOARD_DATA_VOLUME_PATH"

    docker compose \
        -p "$WGDASHBOARD_COMPOSE_PROJECT" \
        --project-directory "$WGDASHBOARD_FOLDER" \
        -f "$WGDASHBOARD_FOLDER/docker-compose.yml" \
        up -d
}

wgdashboard_stop_docker(){
    docker compose \
        -p "$WGDASHBOARD_COMPOSE_PROJECT" \
        --project-directory "$WGDASHBOARD_FOLDER" \
        -f "$WGDASHBOARD_FOLDER/docker-compose.yml" \
        stop
}

wgdashboard_clean_docker(){
    docker compose \
        -p "$WGDASHBOARD_COMPOSE_PROJECT" \
        --project-directory "$WGDASHBOARD_FOLDER" \
        -f "$WGDASHBOARD_FOLDER/docker-compose.yml" \
        down --volumes
}

wgdashboard_backup_docker(){
    if ! docker_project_deployed "$WGDASHBOARD_COMPOSE_PROJECT"; then
        echo "WGDashboard is not deployed, skipping backup"
        return 0
    fi

    docker_volumes_backup "$WGDASHBOARD_COMPOSE_PROJECT" "$WGDASHBOARD_BASE_VOLUMES_PATH" "$WGDASHBOARD_BACKUP_PATH" || exit 1
}

# $1 Backup file name (optional, newest volumes backup by default)
wgdashboard_restore_docker(){
    docker_restore "$WGDASHBOARD_COMPOSE_PROJECT" "$WGDASHBOARD_BASE_VOLUMES_PATH" "$WGDASHBOARD_BACKUP_PATH" "$1" || exit 1
}
