#!/bin/bash

#########################
# NAME: Poll Mem change #
# AUTHOR: DesertRatz    #
# CREATED: 2025/06/22   #
# (C) 2022-2026         #
#########################

# Get the current total RAM size (in KB)
current_total_ram=$(free -m | grep Mem | awk '{print $2}')

# Store the previous RAM size in a file
previous_total_ram_file="/data/swap/previous_total_ram.txt"

# If the file doesn't exist, initialize it with the current RAM size
if [ ! -f $previous_total_ram_file ]; then
    echo $current_total_ram >$previous_total_ram_file
fi

# Get the previous RAM size
previous_total_ram=$(cat $previous_total_ram_file)

# Compare current and previous RAM sizes
if [ "$current_total_ram" != "$previous_total_ram" ]; then
    echo "Memory size changed. Adjusting swap..."

    # Run the swap adjustment script
    /usr/local/bin/configure_swap.sh

    # Update the stored RAM size
    echo $current_total_ram >$previous_total_ram_file
fi