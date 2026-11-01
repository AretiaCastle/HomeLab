#!/bin/bash

DUCKDNS_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DUCKDNS_COMPOSE_PROJECT="${PROJECT}-duckdns"
DUCKDNS_ENV_FILE="$DUCKDNS_FOLDER/.env.duckdns"

check_duckdns_env_files(){
    if [[ ! -f "$DUCKDNS_ENV_FILE" ]]; then
        echo "ERROR: missing file $DUCKDNS_ENV_FILE" >&2
        return 1
    fi

    return 0
}

duckdns_deploy_docker(){
    check_duckdns_env_files || exit 1

    docker compose \
        -p "$DUCKDNS_COMPOSE_PROJECT" \
        --project-directory "$DUCKDNS_FOLDER" \
        -f "$DUCKDNS_FOLDER/docker-compose.yml" \
        up -d
}

# Pull the images of the compose file and recreate the containers that changed
duckdns_update_docker(){
    check_duckdns_env_files || exit 1

    docker compose \
        -p "$DUCKDNS_COMPOSE_PROJECT" \
        --project-directory "$DUCKDNS_FOLDER" \
        -f "$DUCKDNS_FOLDER/docker-compose.yml" \
        pull || exit 1

    duckdns_deploy_docker
}

duckdns_stop_docker(){
    docker compose \
        -p "$DUCKDNS_COMPOSE_PROJECT" \
        --project-directory "$DUCKDNS_FOLDER" \
        -f "$DUCKDNS_FOLDER/docker-compose.yml" \
        stop
}

duckdns_clean_docker(){
    docker compose \
        -p "$DUCKDNS_COMPOSE_PROJECT" \
        --project-directory "$DUCKDNS_FOLDER" \
        -f "$DUCKDNS_FOLDER/docker-compose.yml" \
        down --volumes
}
