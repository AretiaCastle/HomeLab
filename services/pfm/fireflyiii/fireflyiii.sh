#!/bin/bash

FIREFLYIII_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
FIREFLYIII_COMPOSE_PROJECT="${PROJECT}-fireflyiii"
FIREFLYIII_ENV_FILE="$FIREFLYIII_FOLDER/.env.fireflyiii"
FIREFLYIII_DB_ENV_FILE="$FIREFLYIII_FOLDER/.db.env.fireflyiii"

check_fireflyiii_env_files(){
    local missing=false

    if [[ ! -f "$FIREFLYIII_ENV_FILE" ]]; then
        echo "ERROR: missing file $FIREFLYIII_ENV_FILE" >&2
        missing=true
    fi

    if [[ ! -f "$FIREFLYIII_DB_ENV_FILE" ]]; then
        echo "ERROR: missing file $FIREFLYIII_DB_ENV_FILE" >&2
        missing=true
    fi

    if [[ "$missing" == true ]]; then
        return 1
    fi

    return 0
}

load_fireflyiii_env(){
    check_fireflyiii_env_files || return 1

    set -a
    source "$FIREFLYIII_ENV_FILE"
    source "$FIREFLYIII_DB_ENV_FILE"
    set +a
}

fireflyiii_deploy_docker(){
    # FireflyIII
    mkdir -p "$FIREFLYIII_UPLOAD_PATH"
    mkdir -p "$FIREFLYIII_DB_PATH"
    
    docker compose \
        -p "$FIREFLYIII_COMPOSE_PROJECT" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        up -d
}

fireflyiii_stop_docker(){
    docker compose \
        -p "$FIREFLYIII_COMPOSE_PROJECT" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        stop
}

fireflyiii_clean_docker(){
    docker compose \
        -p "$FIREFLYIII_COMPOSE_PROJECT" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        down --volumes
}

# Database dump and uploads export
fireflyiii_export_docker(){
    load_fireflyiii_env || return 1

    local backup_tag="export-$(backup_timestamp)"
    local work_dir="$FIREFLYIII_BACKUP_PATH/$backup_tag"
    local backup_file="$work_dir.tar.gz"
    mkdir -p "$work_dir"

    echo "Creating database dump..."
    if ! docker exec -e MYSQL_PWD="$MYSQL_PASSWORD" fireflyiii_db \
        mariadb-dump -u "$MYSQL_USER" "$MYSQL_DATABASE" > "$work_dir/database.sql"; then
        echo "ERROR: database dump failed!" >&2
        rm -rf "$work_dir"
        return 1
    fi

    # Check for essential database tables
    local table
    for table in users accounts transactions; do
        if ! grep -q "CREATE TABLE \`$table\`" "$work_dir/database.sql"; then
            echo "ERROR: required table '$table' not found in database dump!" >&2
            rm -rf "$work_dir"
            return 1
        fi
    done

    echo "Copying uploads..."
    docker cp fireflyiii_core:/var/www/html/storage/upload "$work_dir/uploads"

    tar -czf "$backup_file" -C "$FIREFLYIII_BACKUP_PATH" "$backup_tag"
    rm -rf "$work_dir"

    backup_write_checksum "$backup_file"
    backup_prune "$FIREFLYIII_BACKUP_PATH" export

    echo "Backup file: $backup_file"
}

# Database dump and uploads import
# $1 Export file path
fireflyiii_import_docker(){
    local backup_file="$1"
    local backup_tag="$(basename "$backup_file" .tar.gz)"

    load_fireflyiii_env || return 1

    if ! docker_project_running "$FIREFLYIII_COMPOSE_PROJECT"; then
        echo "ERROR: Firefly III is not running" >&2
        return 1
    fi

    local restore_dir="$(mktemp -d -p "$FIREFLYIII_BACKUP_PATH")"
    tar -xzf "$backup_file" -C "$restore_dir"
    local restore_path="$restore_dir/$backup_tag"

    if [[ ! -f "$restore_path/database.sql" || ! -d "$restore_path/uploads" ]]; then
        echo "ERROR: database dump or uploads missing in $backup_file" >&2
        rm -rf "$restore_dir"
        return 1
    fi

    echo "Restoring database..."
    if ! docker exec -i -e MYSQL_PWD="$MYSQL_PASSWORD" fireflyiii_db \
        mariadb -u "$MYSQL_USER" "$MYSQL_DATABASE" < "$restore_path/database.sql"; then
        echo "ERROR: database restore failed!" >&2
        rm -rf "$restore_dir"
        return 1
    fi

    echo "Restoring uploads..."
    if ! docker cp "$restore_path/uploads/." fireflyiii_core:/var/www/html/storage/upload/; then
        echo "ERROR: uploads restore failed!" >&2
        rm -rf "$restore_dir"
        return 1
    fi

    rm -rf "$restore_dir"

    echo "Restore completed successfully!"
    echo "Restarting Firefly III container..."
    docker restart fireflyiii_core
}

fireflyiii_backup_docker(){
    if ! docker_project_deployed "$FIREFLYIII_COMPOSE_PROJECT"; then
        echo "Firefly III is not deployed, skipping backup"
        return 0
    fi

    if docker_project_running "$FIREFLYIII_COMPOSE_PROJECT"; then
        fireflyiii_export_docker || exit 1
    else
        echo "WARNING: Firefly III is not running, skipping database export" >&2
    fi

    docker_volumes_backup "$FIREFLYIII_COMPOSE_PROJECT" "$FIREFLYIII_BASE_VOLUMES_PATH" "$FIREFLYIII_BACKUP_PATH" || exit 1
}

# $1 Backup file name (optional, newest volumes backup by default)
fireflyiii_restore_backup_docker(){
    docker_restore "$FIREFLYIII_COMPOSE_PROJECT" "$FIREFLYIII_BASE_VOLUMES_PATH" "$FIREFLYIII_BACKUP_PATH" "$1" fireflyiii_import_docker || exit 1
}
