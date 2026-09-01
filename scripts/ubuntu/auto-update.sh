#########################
# NAME: Ubuntu Update	#
# AUTHOR: DesertRatz	#
# CREATED: 2025/12/08	#
# (C) 2022-2026			#
#########################

#!/bin/bash

# Ensure the script is ran as root
if [[$EUID -ne 0]]; then
    echo "This script must be ran as root. Use sudo."
    exit 1
fi

# Log file for tracking the updates
LOG_FILE="/var/log/ubuntu-updates.log"

# Log message function
log_message() {
    echo "$(date '+%Y%m%d_%H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Determine if any package(s) are on hold
chk_hld_pkg() {
    local held_packages=$(apt-mark showhold)
    if [[-n "$held_packages"]]; then
        log_message "WARNING: The following packages are on hold and will NOT be updated:"
        log_message "$held_packages"
        return 1
    fi
    return 0
}

# Perform system update(s)
perform_the_work() {
    log_message "Starting system update process..."

    # Update the package list
    apt update

    # Check for available upgrades
    upgrades=$(apt -s upgrade | grep "upgraded" | cut -d' ' -f1)

    if [["$upgrades" -eq 0]]; then
        log_message "No system updates available."
        return 0
    fi

    log_message "Found $upgrades package(s) to upgrade."

    # Perform the following
    apt upgrade -y
    apt autoremove -y
    apt autoclean

    log_message "System update completed..."
    return 0
}

# Determine if the device needs to restart
chk_restart_required(){
    if [-f /var/run/reboot-required]; then
        log_message "System restart required after updates."
        return 0
    fi
    return 1
}

# Main script
main() {
    log_message "Starting update script"

    # Check for held packages
    if ! chk_hld_pkg; then
        log_message "Held packages detected. Manual update maybe required."
        exit 1
    fi

    # Perform the update
    perform_the_work

    # Determine if a reboot is needed
    if chk_restart_required; then
        log_message "Restarting device in 5 minutes..."
        shutdown -r +5 "System restart required after updates. Save your work."
    else
        log_message "No system restart required."
    fi

    log_message "Update script completed"
}

# Execute the main
main