#!/bin/bash

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: ./restore_firefly_docker.sh path/to/backup.tar.gz"
    exit 1
fi

# Prompt for database password
read -sp "Enter database password: " DB_PASSWORD
echo "" # Add newline after password input

# Validate password by trying to list databases
if ! docker exec -i firefly_iii_db mariadb -u firefly -p"${DB_PASSWORD}" -e "SHOW DATABASES;" > /dev/null 2>&1; then
    echo "Error: Invalid database password"
    exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="firefly_restore_temp"

# Extract the backup
echo "Extracting backup..."
mkdir -p $RESTORE_DIR
tar -xzf $BACKUP_FILE -C $RESTORE_DIR

# Find the extracted directory (it should be named with a date)
EXTRACTED_DIR=$(ls $RESTORE_DIR/firefly_backups)
FULL_RESTORE_PATH="$RESTORE_DIR/firefly_backups/$EXTRACTED_DIR"

# Verify backup contents
if [ ! -f "$FULL_RESTORE_PATH/database.sql" ]; then
    echo "ERROR: Database backup file not found!"
    rm -rf $RESTORE_DIR
    exit 1
fi

if [ ! -d "$FULL_RESTORE_PATH/uploads" ]; then
    echo "ERROR: Uploads directory not found!"
    rm -rf $RESTORE_DIR
    exit 1
fi

# Restore database
echo "Restoring database..."
cat "$FULL_RESTORE_PATH/database.sql" | docker exec -i firefly_iii_db mariadb -u firefly -p"${DB_PASSWORD}" firefly
if [ $? -ne 0 ]; then
    echo "ERROR: Database restore failed!"
    rm -rf $RESTORE_DIR
    exit 1
fi

# Restore uploads
echo "Restoring uploads..."
docker cp "$FULL_RESTORE_PATH/uploads/." firefly_iii_core:/var/www/html/storage/upload/
if [ $? -ne 0 ]; then
    echo "ERROR: Uploads restore failed!"
    rm -rf $RESTORE_DIR
    exit 1
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -rf $RESTORE_DIR

echo "Restore completed successfully!"
echo "Restarting Firefly III container..."
docker restart firefly_iii_core 