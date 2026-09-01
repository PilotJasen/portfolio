#!/bin/bash

#########################
# NAME: CheckKSM status	#
# AUTHOR: DesertRatz	#
# CREATED: 2024/03/29	#
# (C) 2024-2026			#
#########################

echo "$(date +"%Y-%m-%d %T"): Status"
echo "Stop ksmtuned. Clear cache and merged page."
service ksmtuned stop
echo 2 >/sys/kernel/mm/ksm/run
echo 3 >/proc/sys/vm/drop_caches

sleep 3

echo "*************************"
free -m
echo "*************************"

service ksmtuned start
echo "$(date +"%Y-%m-%d %T"): ksmtuned start"
#done