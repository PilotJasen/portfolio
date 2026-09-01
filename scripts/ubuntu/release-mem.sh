#!/bin/bash

#########################
# NAME: Release memory  #
# AUTHOR: DesertRatz    #
# CREATED: 2025/06/22   #
# (C) 2022-2026         #
#########################

#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (e.g., with sudo)"
    exit 1
fi

echo "🧹 Releasing cached memory..."

# Optional: sync filesystem buffers before clearing cache
sync

# Clear PageCache, dentries, and inodes
echo 3 >/proc/sys/vm/drop_caches

echo "✅ Cache cleared."