#!/bin/bash

#########################
# NAME: Auto Start VM   #
# AUTHOR: DesertRatz    #
# CREATED: 2025/02/14   #
# (C) 2022-2026         #
#########################

# List of VM IDs to start (this can be modified to fit your needs).
VM_IDS=("201" "101") # Change the IDs as needed. (JEA_20250214)

# We will add a delay between each VM start. (JEA_20250214)
DELAY=120

# We will put the logs into the following folder. (JEA_20250214).
LOG_FILE="/var/log/proxmox-vm-start.log"

# This is the log function.
log() {
	echo "$(date +'%Y-%m-%d_%H%M') - $1" >> $LOG_FILE
}

# We will start the VMs with the defined delay.
for vmID in "${VM_IDS[@]}"; do
	log "Attempting to start VM ${vmID}"

	# We will start the VM(s) using the following command.
	qm start "$vmID"

	# We will check and see if the VM started.
	if [ $? -eq 0 ]; then
		log "VM ${vmID} started successfully."
	else
		log "ERROR: VM ${vmID} failed to start."

		# We will retrieve the logs for the specific VM.
		qm status "$vmID" > "$LOG_FILE"

		# We will attempt to determine the error.
		ERROR_MSG=$(qm status "$vmID" 2>&1)
		log "Error details: ${ERROR_MSG}"
	fi

	# We will start the next VM after the delay.
	sleep $DELAY
done