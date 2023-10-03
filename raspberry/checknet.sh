###########################
# NAME: Check Network     #
# AUTHOR: DesertRatz      #
# CREATED: 2022/08/27     #
# (C) 2022-2023           #
###########################

# Supply the IP you want to ping.
ping -c4 000.000.0.0 >/dev/null

if [ $? != 0 ]; then
  echo "No network connection, restarting network"
  /sbin/ifdown 'eth0'
  sleep 5
  /sbin/ifup --force 'eth0'
fi
