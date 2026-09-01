#########################
# NAME: backup HAOS     #
# AUTHOR: DesertRatz    #
# CREATED: 2026/04/29   #
# (C) 2022-2026         #
#########################

#!/bin/bash

# Environment setup
SRC="/data/docker/haos/ha/cfg/backups/" # haOS source directory
DEST="/data/docker/habk/" # haOS destination directory
LOG_FILE="/data/docker/logs/haos-backup.log" # haOS logs directory

MAX_RETRIES=3
RETRY_DELAY=5

# Prepare environment
mkdir -p "$DEST"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - $1" >> "$LOG_FILE"
}

# Sanity checks
if [ ! -d "$SRC" ]; then
    log "ERROR: Source directory does not exist: $SRC"
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    log "ERROR: rsync is not installed"
    exit 1
fi

# Backup execution with retry
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    log "Backup attempt $attempt started"

    rsync -av \
        --ignore-existing \
        --partial \
        --timeout=30 \
        "$SRC/" "$DEST/" >> "$LOG_FILE" 2>&1

    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        log "Backup completed successfully"
        exit 0
    else
        log "ERROR: rsync failed with exit code $STATUS"
        log "Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi

    attempt=$((attempt + 1))
done

log "ERROR: Backup failed after $MAX_RETRIES attempts"
exit 1