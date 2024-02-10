#!/bin/bash

##########################
# NAME: Get Temperature  #
# AUTHOR: DesertRatz     #
# CREATED: 2022/08/27    #
# (C) 2022-2024          #
##########################

# We will run the RPi vcgen to obtain the temperatures. (JEA_20240210)
cpu=$(/usr/bin/vcgencmd measure_temp | awk -F "[=\']" '{print $2}')

# We will convert the temp "C" to temp "F". (JEA_20240210)
cpuf=$(echo "(1.8 * $cpu) + 32" | bc)

# We will format the output here. (JEA_20240210)
echo "$(date) @ $(hostname)"
echo "----------------------------"
echo "CPU => $cpu'C ($cpuf'F)"