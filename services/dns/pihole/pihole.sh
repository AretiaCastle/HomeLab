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

pihole_backup_docker() {
    check_pihole_container_running || exit 1

    local backup_tag="$(date +%Y%m%d)"
    BACKUP_FILE="$PIHOLE_BACKUP_PATH/$backup_tag.zip"
    mkdir -p "$PIHOLE_BACKUP_PATH"

    # Teleporter export (config, lists, groups, clients and DHCP leases)
    echo "Creating Teleporter backup..."
    if ! docker exec pihole sh -c "
        rm -rf $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        mkdir -p $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        cd $PIHOLE_CONTAINER_TELEPORTER_DIR && \
        pihole-FTL --teleporter > /dev/null && \
        mv pi-hole_*_teleporter_*.zip teleporter.zip"; then
        echo "ERROR: Teleporter export failed!"
        exit 1
    fi

    docker cp pihole:"$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip" "$BACKUP_FILE"
    docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"

    # Verify the backup
    echo "Verifying backup..."
    verify_pihole_docker_backup "$BACKUP_FILE"

    # Calculate and store checksums
    echo "Calculating checksums..."
    sha256sum "$BACKUP_FILE" > "$BACKUP_FILE.sha256"

    echo "Backup verification completed successfully!"
    echo "Backup file: $BACKUP_FILE"
    echo "Checksum file: $BACKUP_FILE.sha256"
}

verify_pihole_docker_backup() {
    local backup_file="$1"

    if [ ! -s "$backup_file" ]; then
        echo "ERROR: Teleporter archive is empty or missing!"
        exit 1
    fi

    # Zip archives start with the "PK" signature
    if [ "$(head -c 2 "$backup_file")" != "PK" ]; then
        echo "ERROR: $backup_file is not a valid zip archive!"
        exit 1
    fi
}

pihole_restore_backup_docker() {
    check_pihole_container_running || exit 1

    local backup_name="$1"
    # If no backup file is provided, pick the newest date-based backup name.
    if [[ -z "$backup_name" ]]; then
        backup_name=$(find "$PIHOLE_BACKUP_PATH" -maxdepth 1 -type f -name "*.zip" -printf "%f\n" 2>/dev/null | sort -r | head -n 1)

        if [[ -z "$backup_name" ]]; then
            echo "ERROR: No backup files found in $PIHOLE_BACKUP_PATH" >&2
            exit 1
        fi

        echo "No backup provided. Using latest backup: $backup_name"
    fi

    BACKUP_FILE="$PIHOLE_BACKUP_PATH/$backup_name"

    # Verify backup integrity
    verify_pihole_docker_backup "$BACKUP_FILE"
    if [ -f "$BACKUP_FILE.sha256" ]; then
        echo "Verifying checksum..."
        if ! sha256sum -c --status "$BACKUP_FILE.sha256"; then
            echo "ERROR: Checksum verification failed!"
            exit 1
        fi
    fi

    # Teleporter import
    echo "Restoring Teleporter backup..."
    docker exec pihole sh -c "rm -rf $PIHOLE_CONTAINER_TELEPORTER_DIR && mkdir -p $PIHOLE_CONTAINER_TELEPORTER_DIR"
    docker cp "$BACKUP_FILE" pihole:"$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip"
    if ! docker exec pihole pihole-FTL --teleporter "$PIHOLE_CONTAINER_TELEPORTER_DIR/teleporter.zip"; then
        echo "ERROR: Teleporter import failed!"
        docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"
        exit 1
    fi

    # Cleanup
    echo "Cleaning up temporary files..."
    docker exec pihole rm -rf "$PIHOLE_CONTAINER_TELEPORTER_DIR"

    echo "Restore completed successfully!"
    echo "Restarting Pi-hole container..."
    docker restart pihole
}
