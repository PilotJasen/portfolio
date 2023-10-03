#!/bin/bash

##########################
# NAME: Get Temperature  #
# AUTHOR: DesertRatz     #
# CREATED: 2022/08/27    #
# (C) 2022-2023          #
##########################

#This function will call the raspberry pi "vcgencmd measure_temp".
cpu=$(/usr/bin/vcgencmd measure_temp | awk -F "[=\']" '{print $2}')

#gpu=$(/usr/bin/vcgencmd measure_temp | awk -F "[=\']" '{print $2}')

#cpu=$(</sys/class/thermal/thermal_zone0/temp)

#cpu=$(echo "$cpu / 100 * 0.1" | bc)
cpuf=$(echo "(1.8 * $cpu) + 32" | bc)

#gpuf=$(echo "(1.8 * $gpu) + 32" |bc)

echo "$(date) @ $(hostname)"
echo "-------------------------------------------"
#echo "GPU => $gpu'C ($gpuf'F)"
echo "CPU => $cpu'C ($cpuf'F)"
