###########################
# NAME: System Info Tool  #
# AUTHOR: JArmstrong      #
# CREATED: 2025/10/16     #
# (C) 2024-2026           #
###########################

<#
.SYNOPSIS
    System Information Retrieval Tool

.DESCRIPTION
    This script provides a simple interface to retrieve various hardware and software information about the current device. It's designed to run without administrative privileges. To run this script simply double-click the file.

    Information CAT:
        - CPU details
        - Memory config
        - System serial number and model
        - OS details
        - Disk info
        - All of the above

.NOTES
    Requirements:
        - This script is recommended on Windows 10 or later
        - PowerShell 5.1 or later
#>

# PowerShell app var
$AppName = "System Info Tool"

# PowerShell error var
$PS_ERR_CPU_Retrieval = "Unable to retrieve CPU information: $_"
$PS_ERR_DiskInfo_Retrieval = "Unable to retrieve disk information: $_"
$PS_ERR_Mem_Retrieval = "Unable to retrieve Memory information: $_"
$PS_ERR_OS_Retrieval = "Unable to retrieve OS information: $_"
$PS_ERR_SerialNum_Retrieval = "Unable to retrieve serial number: $_"

# Format the header
function Show-Header {
    param ([string]$title)

    Write-Host "$('*' * 20)" -ForegroundColor Cyan
    Write-Host "* $title *" -ForegroundColor White
    Write-Host "$('*' * 20)" -ForegroundColor Cyan
}

# This function retrieves the CPU information
function Get-CPUInfo {
    Write-Host ""
    Show-Header "CPU Information"

    try {
        $cpu = Get-WmiObject -Class Win32_Processor -ErrorAction Stop

        Write-Host "Processor:      " -NoNewline -ForegroundColor Yellow
        Write-Host $cpu.Name

        Write-Host "Speed:          " -NoNewline -ForegroundColor Yellow
        Write-Host "$($cpu.MaxClockSpeed) MHz"

        Write-Host "Cores:          " -NoNewline -ForegroundColor Yellow
        Write-Host $cpu.NumberOfCores

        Write-Host "Logical Cores:  " -NoNewline -ForegroundColor Yellow
        Write-Host $cpu.NumberOfLogicalProcessors

        Write-Host "Architecture:   " -NoNewline -ForegroundColor Yellow
        switch ($cpu.AddressWidth) {
            32 { Write-Host "32-bit" }
            64 { Write-Host "64-bit" }
            default { Write-Host "Unknown" }
        }
    }
    catch {
        Write-Host "$PS_ERR_CPU_Retrieval" -ForegroundColor Red
    }
}

# This function will retrieve the memory information
function Get-MemInfo {
    Write-Host ""
    Show-Header "Memory Information"

    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        $totalMem = [System.Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMem = [System.Math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMem = [System.Math]::Round($totalMem - $freeMem, 2)
        $percentUsed = [System.Math]::Round(($usedMem / $totalMem) * 100, 0)

        Write-Host "Total Memory:      " -NoNewline -ForegroundColor Yellow
        Write-Host "$totalMem GB"

        Write-Host "Used Memory:       " -NoNewline -ForegroundColor Yellow
        Write-Host "$usedMem GB ($percentUsed%)"

        Write-Host "Free Memory:       " -NoNewline -ForegroundColor Yellow
        Write-Host "$freeMem GB"

        # Retrieve physical memory modules
        <#$physMem = Get-WmiObject -Class Win32_PhysicalMemory -ErrorAction Stop
        if ($physMem) {
            Write-Host "`nPhysical Memory sticks:" -ForegroundColor Yellow
            $modCount = 1
            foreach ($mod in $physMem) {
                $capacityGB = [System.Math]::Round($mod.Capacity / 1GB.2)
                Write-Host "Stick $modCount`: $capacityGB GB ($($mod.Speed) MHz)"
                $modCount++
            }
        }#>
    }
    catch {
        Write-Host "$PS_ERR_Mem_Retrieval" -ForegroundColor Red
    }
}

# This function retrieves the device information
function Get-SerialNumInfo {
    Write-Host ""
    Show-Header "Device Information"

    try {
        $bios = Get-WmiObject -Class Win32_BIOS -ErrorAction Stop
        $system = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop

        Write-Host "System Manufacturer: " -NoNewline -ForegroundColor Yellow
        Write-Host $system.Manufacturer

        Write-Host "System Model:        "  -NoNewline -ForegroundColor Yellow
        Write-Host $system.Model

        Write-Host "Serial Number:       " -NoNewline -ForegroundColor Yellow
        Write-Host $bios.SerialNumber
    }
    catch {
        Write-Host "$PS_ERR_SerialNum_Retrieval" -ForegroundColor Red
    }
}

# This function retrieves the OS information
function Get-OSInfo {
    Write-Host ""
    Show-Header "OS Information"

    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop

        Write-Host "OS Name:        " -NoNewline -ForegroundColor Yellow
        Write-Host $os.Caption

        Write-Host "Version:        " -NoNewline -ForegroundColor Yellow
        Write-Host $os.Version

        Write-Host "Build:          " -NoNewline -ForegroundColor Yellow
        Write-host $os.BuildNumber

        Write-Host "Architecture:   " -NoNewline -ForegroundColor Yellow
        Write-Host $(if ($os.OSArchitecture) { $os.OSArchitecture } else { "N/A" })

        Write-Host "Install Date:   " -NoNewline -ForegroundColor Yellow
        Write-Host $os.ConvertToDateTime($os.InstallDate)

        Write-Host "Last Boot:      " -NoNewline -ForegroundColor Yellow
        Write-Host $os.ConvertToDateTime($os.LastBootUpTime)

        $uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        Write-Host "Uptime:         " -NoNewline -ForegroundColor Yellow
        Write-Host "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
    }
    catch {
        Write-Host "$PS_ERR_OS_Retrieval" -ForegroundColor Red
    }
}

# This function retrieves the disk information
function Get-DiskInfo {
    Write-Host ""
    Show-Header "Disk Information"

    try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

        foreach ($disk in $disks) {
            $sizeGB = [System.Math]::Round($disk.Size / 1GB, 2)
            $freeGB = [System.Math]::Round($disk.FreeSpace / 1GB, 2)
            $usedGB = [System.Math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
            $percentFree = [System.Math]::Round(($disk.FreeSpace / $disk.Size) * 100, 0)

            Write-Host "Drive $($disk.DeviceID)" -ForegroundColor Green
            Write-Host "Volume Name:    " -NoNewline -ForegroundColor Yellow
            Write-Host $(if ($disk.VolumeName) { $disk.VolumeName } else { "N/A" })

            Write-Host "Size:           " -NoNewline -ForegroundColor Yellow
            Write-Host "$sizeGB GB"

            Write-Host "Used:           " -NoNewline -ForegroundColor Yellow
            Write-Host "$usedGB GB"

            Write-Host "Free:           " -NoNewline -ForegroundColor Yellow
            Write-Host "$freeGB GB ($percentFree% free)"

            Write-Host "File System:    " -NoNewline -ForegroundColor Yellow
            Write-Host $disk.FileSystem

            Write-Host "Drive Serial:   " -NoNewline -ForegroundColor Yellow
            Write-Host $disk.VolumeSerialNumber
        }
    }
    catch {
        Write-Host "$PS_ERR_DiskInfo_Retrieval" -ForegroundColor Red
    }
}

# The main function
function Show-Menu {
    Clear-Host
    Show-Header "$AppName"

    Write-Host "Select information to display:`n" -ForegroundColor Green
    Write-Host " [1] CPU Information" -ForegroundColor Cyan
    Write-Host " [2] Memory Information" -ForegroundColor Cyan
    Write-Host " [3] Serial Information" -ForegroundColor Cyan
    Write-Host " [4] OS Information" -ForegroundColor Cyan
    Write-Host " [5] Disk Information" -ForegroundColor Cyan
    Write-Host " [6] All Information" -ForegroundColor Cyan
    Write-Host " [0] Exit`n" -ForegroundColor Cyan

    Write-Host "Enter your choice: " -NoNewline -ForegroundColor Yellow
}

# The main execution loop
do {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        "1" {
            Get-CPUInfo
            Read-Host "`nPress Enter to continue"
        }
        "2" {
            Get-MemInfo
            Read-Host "`nPress Enter to continue"
        }
        "3" {
            Get-SerialNumInfo
            Read-Host "`nPress Enter to continue"
        }
        "4" {
            Get-OSInfo
            Read-Host "`nPress Enter to continue"
        }
        "5" {
            Get-DiskInfo
            Read-Host "`nPress Enter to continue"
        }
        "6" {
            Clear-Host
            Get-CPUInfo
            Get-MemInfo
            Get-SerialNumInfo
            Get-OSInfo
            Get-DiskInfo
            Read-Host "`nPress Enter to continue"
        }
        Default {
            Write-Host "`nInvalid choice. Enter a number between 0 and 6" -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
    }
} while ($choice -ne "0")