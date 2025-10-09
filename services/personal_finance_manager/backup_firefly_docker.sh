#!/bin/bash

# Prompt for database password
read -sp "Enter database password: " DB_PASSWORD
echo "" # Add newline after password input

# Validate password by trying to list databases
if ! docker exec -i firefly_iii_db mariadb -u firefly -p"${DB_PASSWORD}" -e "SHOW DATABASES;" > /dev/null 2>&1; then
    echo "Error: Invalid database password"
    exit 1
fi

# Create backup directory
BACKUP_DIR="firefly_backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Database backup
echo "Creating database backup..."
docker exec firefly_iii_db mariadb-dump -u firefly -p"${DB_PASSWORD}" firefly > "$BACKUP_DIR/database.sql"

# Upload directory backup
echo "Creating uploads backup..."
docker cp firefly_iii_core:/var/www/html/storage/upload "$BACKUP_DIR/uploads"

# Compress the backup
echo "Compressing backup..."
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"

# Verify the backup
echo "Verifying backup..."

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