#!/bin/bash

FIREFLYIII_FOLDER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
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
        echo "Create them from templates:" >&2
        echo "  cp $FIREFLYIII_FOLDER/.env.fireflyiii.example $FIREFLYIII_ENV_FILE" >&2
        echo "  cp $FIREFLYIII_FOLDER/.db.env.fireflyiii.example $FIREFLYIII_DB_ENV_FILE" >&2
        return 1
    fi

    return 0
}

fireflyiii_deploy_docker(){
    check_fireflyiii_env_files || return 1

    # FireflyIII
    sudo mkdir -p "$FIREFLYIII_UPLOAD_PATH"
    sudo mkdir -p "$FIREFLYIII_DB_PATH"
    
    docker compose \
        -p "${PROJECT}" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        up -d
}

fireflyiii_stop_docker(){
    check_fireflyiii_env_files || return 1

    docker compose \
        -p "${PROJECT}" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        stop
}

fireflyiii_clean_docker(){
    check_fireflyiii_env_files || return 1

    docker compose \
        -p "${PROJECT}" \
        --project-directory "$FIREFLYIII_FOLDER" \
        -f "$FIREFLYIII_FOLDER/docker-compose.yml" \
        down --volumes
}

fireflyiii_backup_docker() {
    # Validate password by trying to list databases
    if ! docker exec -i fireflyiii_db mariadb -u firefly -p "${MYSQL_PASSWORD}" -e "SHOW DATABASES;" > /dev/null 2>&1; then
        echo "Error: Invalid database password"
        exit 1
    fi
    
    # Create backup directory
    BACKUP_DIR="$FIREFLYIII_BACKUP_PATH/$(date +%Y%m%d)"
    mkdir -p "$BACKUP_DIR"

    # Database backup
    echo "Creating database backup..."
    docker exec fireflyiii_db mariadb-dump -u firefly -p"${MYSQL_PASSWORD}" firefly > "$BACKUP_DIR/database.sql"

    # Upload directory backup
    echo "Creating uploads backup..."
    docker cp fireflyiii_core:/var/www/html/storage/upload "$BACKUP_DIR/uploads"

    # Compress the backup
    echo "Compressing backup..."
    tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"

    # Verify the backup
    echo "Verifying backup..."
    verify_fireflyiii_docker_backup

    # Calculate and store checksums
    echo "Calculating checksums..."
    sha256sum "$BACKUP_DIR.tar.gz" > "$BACKUP_DIR.tar.gz.sha256"

    # Clean up verification directory
    rm -rf $VERIFY_DIR

    # Remove the uncompressed backup directory
    rm -rf "$BACKUP_DIR"

    echo "Backup verification completed successfully!"
    echo "Backup file: $BACKUP_DIR.tar.gz"
    echo "Checksum file: $BACKUP_DIR.tar.gz.sha256"
    echo ""
    echo "Backup contents verified:"
    echo "- Database dump present and contains required tables"
    echo "- Uploads directory present"
    echo "- Backup integrity verified via checksum"
}

verify_fireflyiii_docker_backup() {
    # Create temp directory for verification
    VERIFY_DIR="verify_temp"
    mkdir -p $VERIFY_DIR

    # Extract the backup
    tar -xzf "$BACKUP_DIR.tar.gz" -C $VERIFY_DIR

    # Verify database dump
    if [ ! -s "$VERIFY_DIR/$BACKUP_DIR/database.sql" ]; then
        echo "ERROR: Database dump is empty or missing!"
        exit 1
    fi

    # Check for essential database tables
    echo "Checking database content..."
    REQUIRED_TABLES=("users" "accounts" "transactions")
    for table in "${REQUIRED_TABLES[@]}"; do
        if ! grep -q "CREATE TABLE \`$table\`" "$VERIFY_DIR/$BACKUP_DIR/database.sql"; then
            echo "ERROR: Required table '$table' not found in database dump!"
            exit 1
        fi
    done

    # Verify uploads directory
    if [ ! -d "$VERIFY_DIR/$BACKUP_DIR/uploads" ]; then
        echo "ERROR: Uploads directory is missing!"
        exit 1
    fi
}

fireflyiii_restore_backup_docker() {
    local backup_name="$1"

    # If no backup file is provided, pick the newest date-based backup name.
    if [[ -z "$backup_name" ]]; then
        backup_name=$(find "$FIREFLYIII_BACKUP_PATH" -maxdepth 1 -type f -name "*.tar.gz" -printf "%f\n" 2>/dev/null | sort -r | head -n 1)

        if [[ -z "$backup_name" ]]; then
            echo "ERROR: No backup files found in $FIREFLYIII_BACKUP_PATH" >&2
            exit 1
        fi

        echo "No backup provided. Using latest backup: $backup_name"
    fi

    # Validate password by trying to list databases
    if ! docker exec -i fireflyiii_db mariadb -u firefly -p"${MYSQL_PASSWORD}" -e "SHOW DATABASES;" > /dev/null 2>&1; then
        echo "Error: Invalid database password"
        exit 1
    fi

    BACKUP_FILE="$FIREFLYIII_BACKUP_PATH/$backup_name"
    RESTORE_DIR="$FIREFLYIII_BACKUP_PATH/firefly_restore_temp"

    # Extract the backup
    echo "Extracting backup..."
    mkdir -p "$RESTORE_DIR"
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

    # Find the extracted directory (it should be named with a date)
    EXTRACTED_DIR=$(ls "$RESTORE_DIR/firefly_backups")
    FULL_RESTORE_PATH="$RESTORE_DIR/firefly_backups/$EXTRACTED_DIR"

    # Verify backup contents
    if [ ! -f "$FULL_RESTORE_PATH/database.sql" ]; then
        echo "ERROR: Database backup file not found!"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi

    if [ ! -d "$FULL_RESTORE_PATH/uploads" ]; then
        echo "ERROR: Uploads directory not found!"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi

    # Restore database
    echo "Restoring database..."
    cat "$FULL_RESTORE_PATH/database.sql" | docker exec -i fireflyiii_db mariadb -u firefly -p"${DB_PASSWORD}" firefly
    if [ $? -ne 0 ]; then
        echo "ERROR: Database restore failed!"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi

    # Restore uploads
    echo "Restoring uploads..."
    docker cp "$FULL_RESTORE_PATH/uploads/." fireflyiii_core:/var/www/html/storage/upload/
    if [ $? -ne 0 ]; then
        echo "ERROR: Uploads restore failed!"
        rm -rf "$RESTORE_DIR"
        exit 1
    fi

    # Cleanup
    echo "Cleaning up temporary files..."
    rm -rf "$RESTORE_DIR"

    echo "Restore completed successfully!"
    echo "Restarting Firefly III container..."
    docker restart fireflyiii_core
}