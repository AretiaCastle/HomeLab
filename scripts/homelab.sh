#!/bin/bash

# Entry point of the make targets. Make appends its output to LOG_FILE.

HOMELAB_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
SERVICES_DIR="$HOMELAB_DIR/services"
ENV_FILE="${ENV_FILE:-$HOMELAB_DIR/.env}"
BACKUP_CRON_MARKER="# HomeLab backup-all"

source "$HOMELAB_DIR/lib/log.sh"
source "$HOMELAB_DIR/lib/env.sh"

if [[ -z "$LOG_FILE" ]]; then
    echo "ERROR: LOG_FILE is not set, run the actions through make" >&2
    exit 1
fi

# Check the global .env and the required commands. Only errors are printed.
check(){
    local missing_commands=""
    local cmd

    if ! env_check "$ENV_FILE" "$HOMELAB_DIR/.env.example"; then
        log "Requirements check failed"
        return 1
    fi

    while IFS= read -r cmd || [[ -n "$cmd" ]]; do
        cmd="$(echo "${cmd%%#*}" | xargs)"
        [[ -z "$cmd" ]] && continue
        command -v "$cmd" > /dev/null 2>&1 || missing_commands="$missing_commands $cmd"
    done < "$HOMELAB_DIR/requirements.txt"

    if [[ -n "$missing_commands" ]]; then
        log "ERROR: commands not installed:$missing_commands"
        return 1
    fi

    env_load
    log_clean
}

##
# Run an action of a service script after checking its .env. A service without
# .env is not configured on the host: backups skip it, other actions fail.
# $1 Service directory under services (e.g. ingress)
# $2 Action (e.g. deploy)
# $@ Action arguments
##
service_action(){
    local service="$1"
    local action="$2"
    shift 2
    local env_errors
    local env_status

    log "$service: $action started"

    env_errors="$(env_check "$SERVICES_DIR/$service/.env" "$SERVICES_DIR/$service/.env.example" 2>&1)"
    env_status=$?
    if [[ "$env_status" -eq 2 && "$action" == backup ]]; then
        log "$service: not configured on this host. Backup skipped"
        return 0
    elif [[ "$env_status" -ne 0 ]]; then
        echo "$env_errors" >&2
        log "$service: $action failed"
        return 1
    fi

    # Subshell so the service variables do not leak to the next service
    if (env_load "$service" && bash "$SERVICES_DIR/$service/$service.sh" "$action" "$@"); then
        log "$service: $action finished"
    else
        log "$service: $action failed"
        return 1
    fi
}

# Update a service after a backup, so it can be restored if the new version
# fails. The update is cancelled if the backup fails.
# $1 Service directory under services
service_update(){
    local service="$1"

    if ! service_action "$service" backup; then
        log "$service: update cancelled because the backup failed"
        return 1
    fi

    service_action "$service" update
}

# Backup of every service, keeps going if one of them fails
# $@ Services
backup_all(){
    local failed=""
    local service

    log "Backup of all services started"
    for service in "$@"; do
        service_action "$service" backup || failed="$failed $service"
    done

    if [[ -n "$failed" ]]; then
        log "ERROR: backup failed for:$failed"
        return 1
    fi
    log "Backup of all services finished"
}

# Remote backups action (setup, sync or fetch)
# $1 Action
remote_backups(){
    local action="$1"

    log "Remote backups $action started"
    if (env_load && bash "$HOMELAB_DIR/scripts/backup_remote.sh" "$action"); then
        log "Remote backups $action finished"
    else
        log "Remote backups $action failed"
        return 1
    fi
}

# Install (or replace) the cron task that runs backup-all and sync-backups on
# BACKUP_SCHEDULE. With -k sync-backups runs even if some backup fails. The
# output is in the log file of each execution.
schedule_backups(){
    env_load
    local cron_filepath="${CRON_FILEPATH:-/etc/crontab}"
    local cron_task="${BACKUP_SCHEDULE:-30 3 * * *}   $USER    make -k -C $HOMELAB_DIR backup-all sync-backups > /dev/null 2>&1 $BACKUP_CRON_MARKER"

    sudo sed -i "/$BACKUP_CRON_MARKER\$/d" "$cron_filepath" || return 1
    echo "$cron_task" | sudo tee -a "$cron_filepath" > /dev/null || return 1
    log "Backups scheduled in $cron_filepath: $cron_task"
}

unschedule_backups(){
    env_load
    local cron_filepath="${CRON_FILEPATH:-/etc/crontab}"

    sudo sed -i "/$BACKUP_CRON_MARKER\$/d" "$cron_filepath" || return 1
    log "Backups unscheduled from $cron_filepath"
}

# Containers of every compose project named "$PROJECT-<tool>"
status(){
    env_load
    docker ps -a --filter "label=com.docker.compose.project" \
        --format 'table {{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' \
        | awk -v prefix="$PROJECT-" 'NR == 1 || index($1, prefix) == 1'
}

command="$1"
shift

case "$command" in
    check)
        check
        ;;
    service)
        service_action "$@"
        ;;
    update)
        service_update "$@"
        ;;
    backup-all)
        backup_all "$@"
        ;;
    remote)
        remote_backups "$@"
        ;;
    schedule)
        schedule_backups
        ;;
    unschedule)
        unschedule_backups
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 [check|service <service> <action>|update <service>|backup-all <services>|remote <action>|schedule|unschedule|status]" >&2
        exit 1
        ;;
esac
