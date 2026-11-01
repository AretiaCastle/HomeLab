#!/bin/bash

# Logging functions. The output of every make execution is appended to
# LOG_FILE, set by make.

# Print a message with the current time
log(){
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Remove logs older than LOG_RETENTION_DAYS
log_clean(){
    find "$(dirname "$LOG_FILE")" -maxdepth 1 -type f -name '*.log' \
        -mtime +"${LOG_RETENTION_DAYS:-30}" -delete 2> /dev/null || true
}
