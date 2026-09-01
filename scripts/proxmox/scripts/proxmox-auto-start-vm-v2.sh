#!/bin/bash

#########################
# NAME: Auto Start VM   #
# AUTHOR: DesertRatz    #
# CREATED: 2026/02/25   #
# (C) 2022-2026         #
#########################

# Script configuration
readonly SCRIPT_NAME="$(basename "$0)"
readonly LOG_DIR="/var/log"
readonly LOG_FILE="${LOG_DIR}/proxmox-vm-start.log"
readonly VMS=(101 301 401) # Change as needed
readonly STARTUP_DELAY=120 # Change as needed
readonly TIMESTAMP_FORMAT="%Y-%m-%d_%H:M:%S"

# Script function

# init logging with the proper permissions
init_logging() {
    # Create the log directory if it does not exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" || {
            echo "ERROR: Failed to create log directory: $LOG_DIR" >&2
            exit 1
        }
    fi

    # Determine if the log file has the correct permissions
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" || {
            echo "ERROR: Failed to create log file: $LOG_FILE" >&2
            exit 1
        }

        # Change permissions
        chmod 644 "$LOG_FILE" || {
            echo "ERROR: Failed to set permissions on log file" >&2
            exit 1
        }
    fi

    # Verify log write access
    if [[ ! -w "$LOG_FILE" ]]; then
        echo "ERROR: No write permission(s) to log file: $LOG_FILE" >&2
        exit 1
    fi
}

# Log function with timestamp
log_msg() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"$TIMESTAMP_FORMAT")

    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Start first VM
start_vm() {
    local vm_id="$1"

    log_msg "INFO" "Attempting to start VM ${vm_id}"

    if qm start "$vm_id" 2>&1 | tee -a "$LOG_FILE"; then
        log_msg "SUCCESS" "VM ${vm_id} started successfully"
        return 0
    else
        log_msg "ERROR" "Failed to start VM ${vm_id}"
        return 1
    fi
}

# Main script execution
main() {
    log_msg "INFO" "*************************"
    log_msg "INFO" "* Proxmox VM Auto Start *"
    log_msg "INFO" "*************************"
    log_msg "INFO" "Target VMs: ${VMS[*]}"
    log_msg "INFO" "Startup delay between VMs: ${STARTUP_DELAY} seconds"

    local failed_vms=()
    local successful_vms=()

    for i in "${!VMS[@]}"; do
        local vm_id="${VMS[$i]}"

        if start_vm "$vm_id"; then
            successful_vms+=("$vm_id")
        else
            failed_vms+=("$vm_id")
        fi

        # Append delay between VMs (except after the previous)
        if [[ $((i + 1)) -lt ${#VMS[@]} ]]; then
            log_msg "INFO" "Waiting ${STARTUP_DELAY} seconds before starting next VM"
            sleep "$STARTUP_DELAY"
        fi
    done

    # Create the summary
    log_msg "INFO" "******************"
    log_msg "INFO" "* Script Summary *"
    log_msg "INFO" "******************"
    log_msg "INFO" "Successful starts: ${#successful_vms[@]} - [${successful_vms[*]}]"
    log_msg "INFO" "Failed starts: ${#failed_vms[@]} - [${failed_vms[*]}]"

    # Exit with appropriate code
    if [[ ${#failed_vms[@]} -gt 0 ]]; then
        log_msg "ERROR" "Script completed with errors"
        return 1
    else
        log_msg "INFO" "Script completed successfully"
        return 0
    fi
}

# Script entry point

# Determine current user (must be root)
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script needs to run as root" >&2
    exit 1
fi

# Init the logging
init_logging

# Execute the script
main
exit $?