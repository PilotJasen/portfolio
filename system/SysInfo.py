###########################
# NAME: System Info       #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/07     #
# (C) 2022-2023           #
###########################

import psutil
import platform
from datetime import datetime


# Define scale size.
def get_size(bytes, suffix="B"):
    """Scale bytes to their proper format.
    i.e.:
        1024000B (bytes) -> 1.024MB
        1024M (Megabytes) -> 1.00GB"""

    factor = 1024
    for unit in ["", "K", "M", "G", "T", "P"]:
        if bytes < factor:
            return f"{bytes:.2f}{unit}{suffix}"
        bytes /= factor


print("="*20, "System Information", "="*20)
uname = platform.uname()

# We will obtain the following: System, Node Name, Release, Version, Machine, Processor.
print(f"System: {uname.system}")
print(f"Node Name: {uname.node}")
print(f"Release: {uname.release}")
print(f"Version: {uname.version}")
print(f"Machine: {uname.machine}")
print(f"Processor: {uname.processor}")

# We will get the system uptime.
print("="*20, "Uptime", "="*20)
boot_time_timestamp = psutil.boot_time()
bt = datetime.fromtimestamp(boot_time_timestamp)
# Print the uptime. Exclude boot time seconds.
print(f"Uptime: {bt.year}/{bt.month}/{bt.day} {bt.hour}:{bt.minute}")

# Get CPU information.
print("="*20, "CPU Info", "="*20)
# Number of physical cores.
print("Physical cores:", psutil.cpu_count(logical=False))
print("Total cores:", psutil.cpu_count(logical=True))

# Get CPU frequency.
cpufreq = psutil.cpu_freq()
print(f"Max Frequency: {cpufreq.max:.2f}MHz")
print(f"Min Frequency: {cpufreq.min:.2f}MHz")
print(f"Current Frequency: {cpufreq.current:.2f}MHz")

# Get CPU usage.
print("CPU Usage Per Core:")
for i, percentage in enumerate(psutil.cpu_percent(percpu=True, interval=1)):
    print(f"Core {i}: {percentage}%")
print(f"Total CPU Usage: {psutil.cpu_percent()}%")

# Get Memory information.
print("="*20, "Mem Info", "="*20)

# Get Memory details.
svmem = psutil.virtual_memory()
print(f"Total: {get_size(svmem.total)}")
print(f"Available: {get_size(svmem.available)}")
print(f"Used: {get_size(svmem.used)}")
print(f"Percentage: {svmem.percent}%")

# Get Memory swap (optional).
print("="*20, "SWAP", "="*20)
swap = psutil.swap_memory()
print(f"Total: {get_size(swap.total)}")
print(f"Free: {get_size(swap.free)}")
print(f"Used: {get_size(swap.used)}")
print(f"Percentage: {swap.percent}%")

# Get Disk information.
print("="*20, "Disk Info", "="*20)
print("Partitions and Usage:")

# Get all partitions.
partitions = psutil.disk_partitions()
for partition in partitions:
    print(f"==Device: {partition.device}==")
    print(f" Mount: {partition.mountpoint}")
    print(f" File system type: {partition.fstype}")
    try:
        partition_usage = psutil.disk_usage(partition.mountpoint)
    # This can happen if the disk is not ready.
    except PermissionError:
        continue
    print(f"  Total Size: {get_size(partition_usage.total)}")
    print(f"  Used: {get_size(partition_usage.used)}")
    print(f"  Free: {get_size(partition_usage.free)}")
    print(f"  Percentage: {partition_usage.percent}%")

# Get Disk I/O stats since boot.
disk_io = psutil.disk_io_counters()
print(f"Total read: {get_size(disk_io.read_bytes)}")
print(f"Total write: {get_size(disk_io.write_bytes)}")

# Get Network information.
print(f"="*20, "Network Info", "="*20)

# Get all interfaces (physical/virtual).
if_addrs = psutil.net_if_addrs()
for interface_name, interface_addresses in if_addrs.items():
    for address in interface_addresses:
        print(f"==Interface: {interface_name}==")
        if str(address.family) == 'AddressFamily.AF_INET':
            print(f"  IP Address: {address.address}")
            print(f"  Netmask: {address.netmask}")
            print(f"  Broadcast IP: {address.broadcast}")
        elif str(address.family) == 'AddressFamily.AF_PACKET':
            print(f"  MAC Address: {address.address}")
            print(f"  Netmask: {address.netmask}")
            print(f"  Broadcast MAC: {address.broadcast}")

# Get Net I/O stats since boot.
net_io = psutil.net_io_counters()
print(f"Total Bytes Sent: {get_size(net_io.bytes_sent)}")
print(f"Total Bytes Received: {get_size(net_io.bytes_recv)}")
