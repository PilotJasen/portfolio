#############################
# NAME: Account Seeker      #
# AUTHOR: DesertRatz        #
# CREATED: 2025/08/06       #
# (C) 2024-2026             #
#############################

<#
.SYNOPSIS
    Searches for locked user accounts in a specified OU with filtering capabilities.

.DESCRIPTION
    This PowerShell scrip performs a READ-ONLY search for locked user accounts within a specified OU.
    It filters out accounts that contain exclusion keywords and displays the results in a human formatted manner.

    Key features:
    - Searches only for locked accounts (excluding computer accounts).
    - Filters out accounts with the following keywords: disabled, inactive, DRP, hold, holding, legal, and delete.
    - Sorts the results (A - Z) by name.
    - Highlights locked accounts in red for visibility.
    - Provides clear messaging when no locked accounts are detected.

.NOTES
    This script is a READ-ONLY app. To unlock accounts you need administrative privileges.
#>

# PowerShell custom var
$PS_CST_ADmod_Error = "Error loading AD module. Ensure the module is installed."
$PS_CST_ADmod_Loaded = "Active Directory module loaded."
$PS_CST_All_Clear = "No locked accounts detected."
#$PS_CST_Locked_Detected = "Found $($FilteredAcct.Count) locked account(s):"
$PS_CST_Locked_Report = "Locked Accounts Report"
$PS_CST_OU_Error = "Error: The specified OU does not exist or you do not have permissions to access it."
$PS_CST_SarError = "Error searching for locked accounts."

# Import the Active Directory module
if (-not (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "$PS_CST_ADmod_Loaded"
    }
    catch {
        Write-Host "$PS_CST_ADmod_Error" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Red
    }
}

# Define the OU to search within
$OU = ""

# Define the exclusion keywords
$Exclude_Keywords = @('disabled', 'inactive', 'DRP', 'hold', 'holding', 'legal', 'delete')

# Determine if the OU exists
try {
    #$OUexist = Get-ADOrganizationalUnit -Identity $OU -ErrorAction Stop
    Write-Host "Searching for OU" -ForegroundColor Cyan
}
catch {
    Write-Host "$PS_CST_OU_Error" -ForegroundColor
    Write-Host "Error details: $_" -ForegroundColor Red
    exit
}

# Search for locked accounts
try {
    $LockedAcct = Search-ADAccount -LockedOut -SearchBase $OU -UsersOnly | Select-Object Name, SamAccountName, DistinguishedName
}
catch {
    Write-Host "$PS_CST_SarError" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    exit
}

# Filter based on exclusion keys
$FilteredAcct = $LockedAcct | Where-Object {
    $account = $_
    $exclude = $false

    foreach ($keyword in $Exclude_Keywords) {
        if ($account.Name -like "*keyword*" -or $account.SamAccountName -like "*keyword*" -or $account.DistinguishedName -like "*keyword*") {
            $exclude = $true
            break
        }
    }
    -not $exclude
} | Sort-Object Name

# Display the results
Clear-Host

Write-Host "*******************************" -ForegroundColor Cyan
Write-Host "* $PS_CST_Locked_Report      *"
Write-Host "* Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm') *"
Write-Host "*******************************" -ForegroundColor Cyan

if ($FilteredAcct.Count -eq 0) {
    Write-Host "$PS_CST_All_Clear" -ForegroundColor Green
}

else {

    #Write-Host "$PS_CST_Locked_Detected" -ForegroundColor Red

    # Display the formatted results
    $FilteredAcct | ForEach-Object {
        Write-Host "===============================" -ForegroundColor Red
        Write-Host "Name: " -NoNewline
        Write-Host $_.Name
        Write-Host "Username: " -NoNewline
        Write-Host $_.SamAccountName
        Write-Host "Distinguished Name: $($_.DistinguishedName)"
        Write-Host "===============================" -ForegroundColor Red
        Write-Host "`n"
    }
}

Read-Host -Prompt "Press Enter to Exit"