#!/bin/bash

#########################
# NAME: Adjust swap     #
# AUTHOR: DesertRatz    #
# CREATED: 2025/06/22   #
# (C) 2022-2026         #
#########################

# Define desired swap size in gigabytes
SWAP_SIZE_GB=8
SWAPFILE="/swapfile"
FSTAB="/etc/fstab"

# Convert GB to MB
SWAP_SIZE_MB=$((SWAP_SIZE_GB * 1024))

# Turn off current swap if active
if swapon --show | grep -q "$SWAPFILE"; then
    echo "Turning off active swap..."
    sudo swapoff "$SWAPFILE"
fi

# Remove old swap file if it exists
if [ -f "$SWAPFILE" ]; then
    echo "Removing old swapfile..."
    sudo rm -f "$SWAPFILE"
fi

# Create new swap file
echo "Creating a $SWAP_SIZE_GB GB swap file at $SWAPFILE..."
sudo fallocate -l "${SWAP_SIZE_GB}G" "$SWAPFILE" || sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count="$SWAP_SIZE_MB"
sudo chmod 600 "$SWAPFILE"
sudo mkswap "$SWAPFILE"
sudo swapon "$SWAPFILE"

# Check if /etc/fstab contains a swapfile entry
if grep -q "$SWAPFILE" "$FSTAB"; then
    echo "Updating existing swapfile entry in $FSTAB..."
    sudo sed -i "s|^.*$SWAPFILE.*|$SWAPFILE none swap sw 0 0|" "$FSTAB"
else
    echo "Adding new swapfile entry to $FSTAB..."
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a "$FSTAB"
fi

echo "Swap setup complete. Current swap usage:"
#swapon --show