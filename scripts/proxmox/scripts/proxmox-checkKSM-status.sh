#!/bin/bash

#########################
# NAME: CheckKSM status	#
# AUTHOR: DesertRatz	#
# CREATED: 2025/02/18	#
# (C) 2024-2026			#
#########################

# Custom variables. (JEA-20250218)
NOT_SUDO_SCRIPT="Error: Unable to run script. Re-run as 'root'."
KSM_DISABLED_MSG="KSM is not enabled or an error occurred while checking the status."
KSM_CLEAR_SUCCESS_MSG="KSM memory holds have been cleared."
KSM_CLEAR_ERROR_MSG="An error occurred while clearing KSM memory."

# We will write out to the log folder.
LOG_FILE="/var/log/ksm-clear.log"

# We will check if the script is being run as the root user.
if [ "$(id -u)" -ne 0 ]; then
    echo "$NOT_SUDO_SCRIPT" >>"$LOG_FILE"
    exit 1
fi

# We will clear the KSM memory hold(s).
clear_ksm() {
    # We will verify that the KSM is enabled.
    ksm_status=$(cat /sys/kernel/mm/ksm/run 2>/dev/null)
    if [ "$ksm_status" != "0" ]; then # Need to debug. (JEA-20250218)
        echo "$(date) - $KSM_DISABLED_MSG" >>"$LOG_FILE"
        return 1
    fi

    # We will clear the KSM memory.
    service ksmtuned stop
    echo 2 >/sys/kernel/mm/ksm/run
    echo 3 >/proc/sys/vm/drop_caches
    service ksmtuned start

    # We will verify that clearing KSM was successful.
    if [ $? -eq 0 ]; then
        echo "$(date) - $KSM_CLEAR_SUCCESS_MSG" >>"$LOG_FILE"
    else
        echo "$(date) - $KSM_CLEAR_ERROR_MSG" >>"$LOG_FILE"
    fi
}

# We will call the function to clear the KSM memory.
clear_ksm

# Exit with success.
exit 0