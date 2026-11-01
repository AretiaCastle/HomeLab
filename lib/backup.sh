#!/bin/bash

# Shared backup functions for docker based tools.
#
# Backups are stored in the tool backup directory as:
#   volumes-<timestamp>.tar.gz  Cold copy of the tool volumes directory
#   export-<timestamp>.<ext>    Optional application export (portable)
# Each file has its <file>.sha256 next to it.

BACKUP_HELPER_IMAGE="alpine:3.24.3"

backup_timestamp(){
    date +%Y%m%d_%H%M%S
}

docker_project_deployed(){
    local project="$1"
    [[ -n "$(docker ps -aq --filter "label=com.docker.compose.project=$project")" ]]
}

docker_project_running(){
    local project="$1"
    [[ -n "$(docker ps -q --filter "label=com.docker.compose.project=$project")" ]]
}

backup_write_checksum(){
    local file="$1"
    (cd "$(dirname "$file")" && sha256sum "$(basename "$file")" > "$(basename "$file").sha256")
}

backup_verify_checksum(){
    local file="$1"

    if [[ ! -s "$file" ]]; then
        echo "ERROR: backup file $file is empty or missing" >&2
        return 1
    fi

    if [[ ! -f "$file.sha256" ]]; then
        echo "ERROR: checksum file $file.sha256 is missing" >&2
        return 1
    fi

    if ! (cd "$(dirname "$file")" && sha256sum -c --status "$(basename "$file").sha256"); then
        echo "ERROR: checksum verification failed for $file" >&2
        return 1
    fi
}

##
# Print the newest backup file name with the given prefix.
# $1 Backup directory
# $2 Prefix (volumes or export)
##
backup_latest(){
    local backup_path="$1"
    local prefix="$2"
    find "$backup_path" -maxdepth 1 -type f -name "$prefix-*" ! -name "*.sha256" -printf "%f\n" 2>/dev/null \
        | sort -r | head -n 1
}

##
# Keep only the newest BACKUP_RETENTION backups with the given prefix.
# $1 Backup directory
# $2 Prefix (volumes or export)
##
backup_prune(){
    local backup_path="$1"
    local prefix="$2"
    local retention="${BACKUP_RETENTION:-7}"

    find "$backup_path" -maxdepth 1 -type f -name "$prefix-*" ! -name "*.sha256" -printf "%f\n" 2>/dev/null \
        | sort -r | tail -n +"$((retention + 1))" \
        | while IFS= read -r old_backup; do
            echo "Removing old backup $old_backup"
            rm -f "$backup_path/$old_backup" "$backup_path/$old_backup.sha256"
        done
}

##
# Cold backup of a tool volumes directory. The compose project is stopped while
# the copy is made and started again if it was running.
# $1 Compose project
# $2 Volumes directory
# $3 Backup directory
##
docker_volumes_backup(){
    local project="$1"
    local volumes_path="$2"
    local backup_path="$3"
    local backup_name="volumes-$(backup_timestamp).tar.gz"
    local was_running=false
    local status=0

    if [[ ! -d "$volumes_path" ]]; then
        echo "ERROR: volumes directory $volumes_path does not exist" >&2
        return 1
    fi

    mkdir -p "$backup_path"

    if docker_project_running "$project"; then
        was_running=true
        echo "Stopping $project..."
        docker compose -p "$project" stop
    fi

    # Copy from a container to read files owned by any user
    echo "Creating volumes backup $backup_name..."
    docker run --rm \
        -v "$volumes_path:/source:ro" \
        -v "$backup_path:/backup" \
        "$BACKUP_HELPER_IMAGE" \
        sh -c "tar -czf /backup/$backup_name -C /source . && chown $(id -u):$(id -g) /backup/$backup_name" \
        || status=$?

    if [[ "$was_running" == true ]]; then
        echo "Starting $project..."
        docker compose -p "$project" start
    fi

    if [[ "$status" -ne 0 ]] || ! gzip -t "$backup_path/$backup_name"; then
        echo "ERROR: volumes backup failed" >&2
        rm -f "$backup_path/$backup_name"
        return 1
    fi

    backup_write_checksum "$backup_path/$backup_name"
    backup_prune "$backup_path" volumes

    echo "Backup file: $backup_path/$backup_name"
}

##
# Replace a tool volumes directory with a cold backup. The compose project is
# stopped while the data is replaced and started again if it was running.
# $1 Compose project
# $2 Volumes directory
# $3 Backup directory
# $4 Backup file name
##
docker_volumes_restore(){
    local project="$1"
    local volumes_path="$2"
    local backup_path="$3"
    local backup_name="$4"
    local was_running=false
    local status=0

    backup_verify_checksum "$backup_path/$backup_name" || return 1

    mkdir -p "$volumes_path"

    if docker_project_running "$project"; then
        was_running=true
        echo "Stopping $project..."
        docker compose -p "$project" stop
    fi

    echo "Restoring volumes backup $backup_name..."
    docker run --rm \
        -v "$volumes_path:/target" \
        -v "$backup_path:/backup:ro" \
        "$BACKUP_HELPER_IMAGE" \
        sh -c "find /target -mindepth 1 -delete && tar -xzf /backup/$backup_name -C /target" \
        || status=$?

    if [[ "$was_running" == true ]]; then
        echo "Starting $project..."
        docker compose -p "$project" start
    fi

    if [[ "$status" -ne 0 ]]; then
        echo "ERROR: volumes restore failed" >&2
        return 1
    fi

    echo "Restore completed successfully!"
}

##
# Restore the backup given by name or, if empty, the newest volumes backup.
# Export backups are restored with the given import function.
# $1 Compose project
# $2 Volumes directory
# $3 Backup directory
# $4 Backup file name (optional)
# $5 Function that imports an export backup, receives the file path
##
docker_restore(){
    local project="$1"
    local volumes_path="$2"
    local backup_path="$3"
    local backup_name="$4"
    local import_function="$5"

    if [[ -z "$backup_name" ]]; then
        backup_name="$(backup_latest "$backup_path" volumes)"
        if [[ -z "$backup_name" ]]; then
            echo "ERROR: no volumes backups found in $backup_path" >&2
            return 1
        fi
        echo "No backup provided. Using latest backup: $backup_name"
    fi

    case "$backup_name" in
        volumes-*)
            docker_volumes_restore "$project" "$volumes_path" "$backup_path" "$backup_name"
            ;;
        export-*)
            if [[ -z "$import_function" ]]; then
                echo "ERROR: $project has no export import" >&2
                return 1
            fi
            backup_verify_checksum "$backup_path/$backup_name" || return 1
            "$import_function" "$backup_path/$backup_name"
            ;;
        *)
            echo "ERROR: unknown backup type $backup_name" >&2
            return 1
            ;;
    esac
}
