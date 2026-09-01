#!/bin/bash

###########################
# NAME: Caddy mkdir       #
# AUTHOR: DesertRatz      #
# CREATED: 2026/07/20     #
# (C) 2022-2026           #
###########################

set -euo pipefail

BASE="/data/desertratz"

echo "======================================"
echo "Docker Directory Initialization"
echo "Base Directory: $BASE"
echo "======================================"

# Verify parent directory exists
if [ ! -d "/data" ]; then
    echo "ERROR: /data does not exist."
    echo "Please verify your storage mount before continuing."
    exit 1
fi

# Create base directory if missing
if [ -d "$BASE" ]; then
    echo "Base directory already exists:"
    echo "  $BASE"
else
    echo "Creating base directory:"
    echo "  $BASE"

    mkdir -p "$BASE"
fi

# Required directory structure
DIRECTORIES=(
    "$BASE/proxy"
    "$BASE/proxy/config"
    "$BASE/proxy/data"
    "$BASE/proxy/logs"
    "$BASE/proxy/backups"
    "$BASE/proxy/certs"
    "$BASE/proxy/certs/namecheap"
    "$BASE/proxy/certs/letsencrypt"
    "$BASE/scripts"
)

echo
echo "Creating required directories..."

for DIR in "${DIRECTORIES[@]}"
do
    if [ -d "$DIR" ]; then
        echo "Exists:  $DIR"
    else
        echo "Create:  $DIR"
        mkdir -p "$DIR"
    fi
done

# Secure certificate storage
echo
echo "Applying certificate directory permissions..."

chmod 700 "$BASE/proxy/certs"

if [ -d "$BASE/proxy/certs/namecheap" ]; then
    chmod 700 "$BASE/proxy/certs/namecheap"
fi

if [ -d "$BASE/proxy/certs/letsencrypt" ]; then
    chmod 700 "$BASE/proxy/certs/letsencrypt"
fi

# Display results
echo
echo "Directory creation completed successfully."

echo
echo "Current structure:"

if command -v tree >/dev/null 2>&1; then
    tree "$BASE"
else
    echo "'tree' is not installed."
    echo "Install with:"
    echo "  sudo apt install tree"
    echo
    find "$BASE" -maxdepth 3 -type d | sort
fi