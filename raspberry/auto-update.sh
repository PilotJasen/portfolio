#########################
# NAME: RPi Auto Update	#
# AUTHOR: DesertRatz	#
# CREATED: 2025/02/09	#
# (C) 2022-2025			#
#########################

#!/bin/bash

# We will update the package list.
sudo apt-get update -y

# Time to upgrade the system.
sudo apt-get upgrade -y

# We will check if a reboot is required.
if [ -f /var/run/reboot-required ]; then
	echo "Reboot Required"
	sudo reboot
else
	echo "No reboot required"
fi