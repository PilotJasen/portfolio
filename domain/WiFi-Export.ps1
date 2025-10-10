###########################
# NAME: WiFi Export Tool  #
# AUTHOR: DesertRatz      #
# CREATED: 2025/10/01     #
# (C) 2024-2025           #
###########################

<#
.SYNOPSIS
    Wi-Fi Profile Exporter

.DESCRIPTION
    This script exports the Wi-Fi profiles (network configs) to an XML file.
    - No administrator privileges required
    - Interactive selection of WiFi profiles to export
    - Custom export location with folder creation if needed
    - Self-contained execution
        - PowerShell changes the execution policy temporarily
#>

# App var
$App_Name = "WiFi Profile Exporter"

# PowerShell custom var
$PS_CST_Created_Export_Dir = "Created export: $exportPath"
$PS_CST_Created_Export_Dir_Failed = "Error creating directory: $_"
$PS_CST_Created_Export_Dir_Temp = "Using temporary directory instead"
$PS_CST_Export_Selected_Invalid = "Invalid selection. Exporting first WiFi profile by default"
$PS_CST_Goodbye = "Press Enter to exit"
$PS_CST_No_WiFi_Profiles = "No WiFi profiles detected"
$PS_CST_Prompt_Export = "Enter the export folder path (press Enter for the default: C:\ttt)" # Change as needed
$PS_CST_Open_Export_Directory = "`nOpen the export directory? (Y/N)"
$PS_CST_Selection_Prompt = "Enter profile number to export ('A' for all)"
$PS_CST_WiFi_Export_Error = "Error while exporting profile '$wifiProfile': $_"
$PS_CST_WiFi_Failed_Export = "Failed to export profile: $wifiProfile"
$PS_CST_WiFi_Profile_Export_Failed = "Profiles failed to export: $errorCount"
$PS_CST_WiFi_Profile_Ret_Error = "Error retrieving WiFi profiles: $_"

# Temporarily set the execution policy to bypass for the process only
$currentPolicy = Get-ExecutionPolicy -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Create a colorful output
function Write-ColorOutput($ForegroundColor) {
    $fc = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $Host.UI.RawUI.ForegroundColor = $fc
}

# Display the welcome message
Write-ColorOutput Cyan "******************************"
Write-ColorOutput Green "*  $App_Name    *"
Write-ColorOutput Cyan "******************************"

# Set the export var
$defaultPath = "C:\ttt"

# Prompt for the export location
$exportPath = Read-Host "$PS_CST_Prompt_Export"

# If blank use the default path
if ([string]::IsNullOrWhiteSpace($exportPath)) {
    $exportPath = $defaultPath
}

# Create the export directory
if (-not (Test-Path -Path $exportPath -PathType Container)) {
    try {
        New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
        Write-ColorOutput Green "$PS_CST_Created_Export_Dir"
    }
    catch {
        Write-ColorOutput Red "$PS_CST_Created_Export_Dir_Failed"
        Write-ColorOutput Yellow "$PS_CST_Created_Export_Dir_Temp"
        $exportPath = [System.IO.Path]::GetTempPath() + "WiFiProfiles"
        New-Item -Path $exportPath -ItemType Directory -Force | Out-Null
    }
}

# Retrieve the WiFi profiles
try {
    $profilesList = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_ -split ":")[-1].Trim() }

    # Filter the PowerShell profile.ps1 to avoid export errors
    $profilesList = $profilesList | Where-Object { $_ -ne "profile.ps1" -and $_ -ne "profile" }

    if ($profilesList.Count -eq 0) {
        Write-ColorOutput Red "$PS_CST_No_WiFi_Profiles"
        Read-Host "$PS_CST_Goodbye"
        exit
    }
}
catch {
    Write-ColorOutput Red "$PS_CST_WiFi_Profile_Ret_Error"
    Read-Host "$PS_CST_Goodbye"
}

# If only one profile, no need for selection
if ($profilesList.Count -eq 1) {
    $selectedProfiles = $profilesList
    Write-ColorOutput Yellow "Found one WiFi profile: $selectedProfiles"
}
else {
    # Display the selection for multiple
    Write-ColorOutput Cyan "`nAvailable WiFi profiles:"
    for ($i = 0; $i -lt $profilesList.Count; $i++) {
        Write-Host "$($i+1). $($profilesList[$i])"
    }

    Write-Host "[A] Export all"

    # Prompt for selection
    $selection = Read-Host "$PS_CST_Selection_Prompt"

    if ($selection -eq "A" -or $selection -eq "a") {
        $selectedProfiles = $profilesList
        Write-ColorOutput Yellow "Exporting all WiFi profiles"
    }
    else {
        $idx = [int]$selection - 1
        if ($idx -ge 0 -and $idx -lt $profilesList.Count) {
            $selectedProfiles = @($profilesList[$idx])
            Write-ColorOutput Yellow "Exporting: $($selectedProfiles[0])"
        }
        else {
            Write-ColorOutput Red "$PS_CST_Export_Selected_Invalid"
            $selectedProfiles = @($profilesList[0])
        }
    }
}

# Export the selected WiFi profiles
$successCount = 0
$errorCount = 0
$exportedFiles = @()

foreach ($wifiProfile in $selectedProfiles) {
    try {
        $fileName = "$exportPath\$($wifiProfile).xml"
        # Sanitize filename
        $fileName = $fileName -replace '[\\\/\:\*\?\"\<\>\|]', '_'

        # Export the profile(s)
        $result = netsh wlan export profile name="$wifiProfile" folder="$exportPath" key=clear

        # Check if export succeeded
        if ($result -match "successfully") {
            $successCount++
            $actualFile = Get-ChildItem -Path $exportPath -Filter "WiFi-$wifiProfile*.xml" | Select-Object -First 1 -ExpandProperty FullName
            if ($actualFile) {
                $exportedFiles += $actualFile
            }
            else {
                $exportedFiles += "$exportPath\WiFi-$wifiProfile.xml"
            }
        }
        else {
            Write-ColorOutput Red "$PS_CST_WiFi_Failed_Export"
            $errorCount++
        }
    }
    catch {
        Write-ColorOutput Red "$PS_CST_WiFi_Export_Error"
        $errorCount++
    }
}

# Show the results
Write-Host ""
Write-Host "******************************" -ForegroundColor Magenta
Write-Host "*    Export Results          *"
Write-Host "* Profiles exported: $successCount       *"
Write-Host "******************************" -ForegroundColor Magenta
if ($errorCount -gt 0) {
    Write-ColorOutput Red "$PS_CST_WiFi_Profile_Export_Failed"
}

# Show the exported files
if ($exportedFiles.Count -gt 0) {
    Write-ColorOutput Cyan "`nExported files:"
    foreach ($file in $exportedFiles) {
        Write-Host "- $file"
    }
    # Open the export directory
    $openDIR = Read-Host "$PS_CST_Open_Export_Directory"
    if ($openDIR -eq "Y" -or $openDIR -eq "y") {
        Start-Process explorer.exe -ArgumentList $exportPath
    }
}

# Restore the original execution policy
Set-ExecutionPolicy -ExecutionPolicy $currentPolicy -Scope Process -Force

Write-Host ""
Read-Host "Press Enter to exit"