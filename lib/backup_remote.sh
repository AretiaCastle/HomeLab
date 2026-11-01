#!/bin/bash

# Synchronization of DEPLOYMENTS_BACKUPS_PATH with a remote host (e.g. a NAS)
# through rsync over ssh.

BACKUP_REMOTE_SSH_KEY="${BACKUP_REMOTE_SSH_KEY:-$HOME/.ssh/homelab_backup}"
BACKUP_REMOTE_PORT="${BACKUP_REMOTE_PORT:-22}"
BACKUP_REMOTE_RETENTION="${BACKUP_REMOTE_RETENTION:-30}"
BACKUP_REMOTE_TARGET="$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST"
BACKUP_REMOTE_SSH="ssh -i $BACKUP_REMOTE_SSH_KEY -p $BACKUP_REMOTE_PORT -o IdentitiesOnly=yes -o BatchMode=yes"

check_backup_remote_config(){
    local missing=false
    local var

    for var in BACKUP_REMOTE_USER BACKUP_REMOTE_HOST BACKUP_REMOTE_PATH DEPLOYMENTS_BACKUPS_PATH; do
        if [[ -z "${!var}" ]]; then
            echo "ERROR: $var is not set" >&2
            missing=true
        fi
    done

    [[ "$missing" == false ]]
}

check_backup_remote_commands(){
    local cmd

    for cmd in "$@"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            echo "ERROR: $cmd is not installed" >&2
            return 1
        fi
    done
}

# Generate the ssh key (if missing), install it in the remote host and create
# the remote backups directory.
backup_remote_setup(){
    check_backup_remote_config || exit 1
    check_backup_remote_commands ssh ssh-keygen ssh-copy-id || exit 1

    if [[ ! -f "$BACKUP_REMOTE_SSH_KEY" ]]; then
        echo "Generating ssh key $BACKUP_REMOTE_SSH_KEY..."
        mkdir -p "$(dirname "$BACKUP_REMOTE_SSH_KEY")"
        ssh-keygen -t ed25519 -N "" -C "homelab-backup@$(hostname)" -f "$BACKUP_REMOTE_SSH_KEY"
    fi

    echo "Installing public key in $BACKUP_REMOTE_TARGET (the remote password is asked once)..."
    if ! ssh-copy-id -i "$BACKUP_REMOTE_SSH_KEY.pub" -p "$BACKUP_REMOTE_PORT" "$BACKUP_REMOTE_TARGET"; then
        echo "ERROR: could not install the key. Add it manually to the remote user authorized keys:" >&2
        cat "$BACKUP_REMOTE_SSH_KEY.pub" >&2
        exit 1
    fi

    if ! $BACKUP_REMOTE_SSH "$BACKUP_REMOTE_TARGET" "mkdir -p '$BACKUP_REMOTE_PATH'"; then
        echo "ERROR: could not create $BACKUP_REMOTE_PATH in $BACKUP_REMOTE_HOST" >&2
        exit 1
    fi

    echo "Remote backups ready in $BACKUP_REMOTE_TARGET:$BACKUP_REMOTE_PATH"
}

# Keep only the newest BACKUP_REMOTE_RETENTION backups of each type and tool in
# the remote host.
backup_remote_prune(){
    $BACKUP_REMOTE_SSH "$BACKUP_REMOTE_TARGET" sh -s -- "'$BACKUP_REMOTE_PATH'" "$BACKUP_REMOTE_RETENTION" <<'EOF'
cd "$1" || exit 1
for dir in */; do
    [ -d "$dir" ] || continue
    for prefix in volumes export; do
        ls -1 "$dir" | grep "^$prefix-" | grep -v '\.sha256$' | sort -r | tail -n +"$(($2 + 1))" |
            while IFS= read -r old_backup; do
                echo "Removing remote backup $dir$old_backup"
                rm -f "$dir$old_backup" "$dir$old_backup.sha256"
            done
    done
done
EOF
}

# Copy the local backups to the remote host. Nothing is deleted remotely
# except by its own retention, so an empty or partial local directory never
# removes remote backups.
backup_remote_sync(){
    if [[ -z "$BACKUP_REMOTE_HOST" ]]; then
        echo "Remote backups not configured, skipping sync"
        return 0
    fi

    check_backup_remote_config || exit 1
    check_backup_remote_commands ssh rsync || exit 1

    if [[ ! -d "$DEPLOYMENTS_BACKUPS_PATH" ]]; then
        echo "ERROR: backups directory $DEPLOYMENTS_BACKUPS_PATH does not exist" >&2
        exit 1
    fi

    echo "Syncing $DEPLOYMENTS_BACKUPS_PATH to $BACKUP_REMOTE_TARGET:$BACKUP_REMOTE_PATH..."
    if ! rsync -a --partial -e "$BACKUP_REMOTE_SSH" \
        "$DEPLOYMENTS_BACKUPS_PATH/" "$BACKUP_REMOTE_TARGET:$BACKUP_REMOTE_PATH/"; then
        echo "ERROR: sync failed" >&2
        exit 1
    fi

    backup_remote_prune || exit 1
    echo "Sync completed successfully!"
}

# Copy the remote backups to the local backups directory (e.g. to restore on a
# new host). Local backups are never deleted.
backup_remote_fetch(){
    check_backup_remote_config || exit 1
    check_backup_remote_commands ssh rsync || exit 1

    mkdir -p "$DEPLOYMENTS_BACKUPS_PATH"

    echo "Fetching $BACKUP_REMOTE_TARGET:$BACKUP_REMOTE_PATH to $DEPLOYMENTS_BACKUPS_PATH..."
    if ! rsync -a --partial -e "$BACKUP_REMOTE_SSH" \
        "$BACKUP_REMOTE_TARGET:$BACKUP_REMOTE_PATH/" "$DEPLOYMENTS_BACKUPS_PATH/"; then
        echo "ERROR: fetch failed" >&2
        exit 1
    fi

    echo "Fetch completed successfully!"
}

action="${1:-sync}"

case "$action" in
    setup)
        backup_remote_setup
        ;;
    sync)
        backup_remote_sync
        ;;
    fetch)
        backup_remote_fetch
        ;;
    *)
        echo "Usage: $0 [setup|sync|fetch]" >&2
        exit 1
        ;;
esac
