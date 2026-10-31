#!/bin/bash

PIHOLE_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PIHOLE_COMPOSE_PROJECT="${PROJECT}-pihole"
PIHOLE_ENV_FILE="$PIHOLE_FOLDER/.env.pihole"
PIHOLE_CONTAINER_TELEPORTER_DIR="/tmp/teleporter"

pihole_baremetal_deployment(){
    # PiHole deployment - installation must run as root
    sudo bash -c 'curl -sSL https://install.pi-hole.net | bash'

    # Be careful to install with root but add the user who launches this script.
    sudo usermod -aG pihole "$USER"

    # Automated backup
    mkdir -p "$PIHOLE_BACKUP_PATH"

    # Backup every day at 03:30 and 04:00
    local cron_filepath="${CRON_FILEPATH:-/etc/crontab}"
    cron_header="# Pihole DNS backup tasks"
    cron_pihole="30 03     * * *   root    cp -r /etc/pihole $PIHOLE_BACKUP_PATH/pihole"
    cron_dnsmasq="00 04     * * *   root    cp -r /etc/dnsmasq.d $PIHOLE_BACKUP_PATH/dnsmasq.d"

    if ! sudo grep -Fqx "$cron_header" "$cron_filepath"; then
        echo "$cron_header" | sudo tee -a "$cron_filepath" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_pihole" "$cron_filepath"; then
        echo "$cron_pihole" | sudo tee -a "$cron_filepath" > /dev/null
    fi
    if ! sudo grep -Fqx "$cron_dnsmasq" "$cron_filepath"; then
        echo "$cron_dnsmasq" | sudo tee -a "$cron_filepath" > /dev/null
    fi
}

check_pihole_env_files(){
    if [[ ! -f "$PIHOLE_ENV_FILE" ]]; then
        echo "ERROR: missing file $PIHOLE_ENV_FILE" >&2
        echo "Create it from template:" >&2
        echo "  cp $PIHOLE_FOLDER/.env.pihole.example $PIHOLE_ENV_FILE" >&2
        return 1
    fi

    return 0
}

check_pihole_container_running(){
    if [[ "$(docker inspect -f '{{.State.Running}}' pihole 2>/dev/null)" != "true" ]]; then
        echo "ERROR: pihole container is not running" >&2
        return 1
    fi

    return 0
}

pihole_deploy_docker(){
    check_pihole_env_files || exit 1

    # Pi-hole
    sudo mkdir -p "$PIHOLE_ETC_PATH"

    docker compose \
        -p "$PIHOLE_COMPOSE_PROJECT" \
        --project-directory "$PIHOLE_FOLDER" \
        -f "$PIHOLE_FOLDER/docker-compose.yml" \
        up -d
}

pihole_stop_docker(){
    docker compose \
        -p "$PIHOLE_COMPOSE_PROJECT" \
        --project-directory "$PIHOLE_FOLDER" \
        -f "$PIHOLE_FOLDER/docker-compose.yml" \
        stop
}

pihole_clean_docker(){
    docker compose \
        -p "$PIHOLE_COMPOSE_PROJECT" \
        --project-directory "$PIHOLE_FOLDER" \
        -f "$PIHOLE_FOLDER/docker-compose.yml" \
        down --volumes
}

# Teleporter export (config, lists, groups, clients and DHCP leases)
pihole_export_docker(){
    local backup_name="export-$(backup_timestamp).zip"
    local backup_file="$PIHOLE_BACKUP_PATH/$backup_name"
    mkdir -p "$PIHOLE_BACKUP_PATH"

    echo "Creating Teleporter export $backup_name..."
    if ! docker exec pihole sh -c "
        rm -rf $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        mkdir -p $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        cd $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        pihole-FTL --teleporter > /dev/null && \
        mv pi-hole_*_teleporter_*.zip teleporter.zip"; then
        echo "ERROR: Teleporter export failed!" >&2
        return 1
    fi

    docker cp pihole:"$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip" "$backup_file"
    docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"

    # Zip archives start with the "PK" signature
    if [[ "$(head -c 2 "$backup_file")" != "PK" ]]; then
        echo "ERROR: $backup_file is not a valid zip archive!" >&2
        rm -f "$backup_file"
        return 1
    fi

    backup_write_checksum "$backup_file"
    backup_prune "$PIHOLE_BACKUP_PATH" export

    echo "Backup file: $backup_file"
}

# Teleporter import
# $1 Export file path
pihole_import_docker(){
    local backup_file="$1"

    check_pihole_container_running || return 1

    echo "Importing Teleporter export $(basename "$backup_file")..."
    docker exec pihole sh -c "rm -rf $PIHOLE_CONTAINER_TELEPORTER_DIR && mkdir -p $PIHOLE_CONTAINER_TELEPORTER_DIR"
    docker cp "$backup_file" pihole:"$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip"
    if ! docker exec pihole pihole-FTL --teleporter "$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip"; then
        echo "ERROR: Teleporter import failed!" >&2
        docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"
        return 1
    fi
    docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"

    echo "Restore completed successfully!"
    echo "Restarting Pi-hole container..."
    docker restart pihole
}

pihole_backup_docker(){
    if ! docker_project_deployed "$PIHOLE_COMPOSE_PROJECT"; then
        echo "Pi-hole is not deployed, skipping backup"
        return 0
    fi

    if docker_project_running "$PIHOLE_COMPOSE_PROJECT"; then
        pihole_export_docker || exit 1
    else
        echo "WARNING: Pi-hole is not running, skipping Teleporter export" >&2
    fi

    docker_volumes_backup "$PIHOLE_COMPOSE_PROJECT" "$PIHOLE_BASE_VOLUMES_PATH" "$PIHOLE_BACKUP_PATH" || exit 1
}

# $1 Backup file name (optional, newest volumes backup by default)
pihole_restore_backup_docker(){
    docker_restore "$PIHOLE_COMPOSE_PROJECT" "$PIHOLE_BASE_VOLUMES_PATH" "$PIHOLE_BACKUP_PATH" "$1" pihole_import_docker || exit 1
}
