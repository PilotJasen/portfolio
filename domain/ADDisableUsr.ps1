###########################
# NAME: ADDisable User    #
# AUTHOR: DesertRatz      #
# CREATED: 2023/06/21     #
# (C) 2022-2023           #
###########################

# The purpose of this script is to automate the process of disabling AD users.

# PowerShell custom vars.
$X_Days = 180 # This value can be changed (range: -1 -> 180).
$judgement_day = -1

param(
    # We will disable all inactive accounts after "X" of days.
    # If the days are set to "-1", then we will not disable them.
    # The default is 180 days.

    [Parameter(Mandatory = $false)] [int] $X_Days,

    # We will delete all inactive accounts after "X" of days.
    # If the days are set to "-1", then we will not delete them.
    # The default is -1.
    [Parameter(Mandatory = $false)] [int] $timesUp = $judgement_day,

    # We create a CSV file to contain all of the disabled users.
    [Parameter(Mandatory = $false)] [string] $logFile = $null,

    # We will create a CSV file to contain all of the deleted users.
    [Parameter(Mandatory = $false)] [string] $deletedUsr = $null
)

# Time to search.
[datetime]$ts = (Get-Date).AddDays(-$X_Days)
$usr = Seach-ADAccount -UsersOnly -AccountInactive -TimeSpan $ts.Day | Select-Object DistinguishedName, sAMAccountName, Enabled
Write-Host "$($usr.Count)"

# We will add the time of the account was disabled (extensionAttribute10).
# This will help while we delete accounts if the "timesUp" is set.
[string]$t = ((Get-Date).DateTime)
$disabled = 0;
$nowDisabled = 0;
$deleted = 0;

# We will determine if we have any disabled accounts.
if ($X_Days -gt -1) {
    foreach ($usr in $users) {
        if ($usr.Enabled) {
            $disabled++
            Set-ADUser $usr.DistinguishedName -add @{extensionAttribute10 = "$t" }
            Disable-ADAccount -Identity $usr.DistinguishedName
        }
        else {
            $nowDisabled++
        }
    }
    # Time to export the disabled accounts.
    if ($logFile) { $usr | Export-Csv "$logFile" }
}

# If the "timesUp" is set, we will delete the account if found.
if ($timesUp -gt -1) {
    $tsD = (Get-Date).AddDays(-$timesUp)
    $usrD = Get-ADUser -filter { enabled -eq $false } -Properties * | Where-Object { 'extensionAttribute10' -in $_.PSobject.Properties.Name } | Where-Object { $tsD -ge $_.extensionAttribute10 }

    foreach ($usr in $usrD) {
        $deleted++
        Remove-ADUser $user
    }

    # We will export the deleted accounts now.
    if ($deletedUsr) { $usrD | Export-Csv "$deletedUsr" }
}

Write-Host ''
Write-Host 'Process complete:'
if ($X_Days -gt -1) {
    Write-Host " - $($disabled) accounts have been disabled ($($nowDisabled) already disabled)."
    if ($logFile) {
        Write-Host "Disabled accounts are logged in $($logFile) file."
    }
}

if ($timesUp -gt -1) {
    Write-Host " - $($deleted) accounts have been deleted."
    if ($deletedUsr) {
        Write-Host "Deleted accounts are logged in $($deletedUsr) file."
    }
}