###########################
# NAME: AAD Sync Mgmt     #
# AUTHOR: DesertRatz      #
# CREATED: 2023/04/19     #
# (C) 2022-2023           #
###########################

<#
.SYNOPSIS
.NOTES
.LINK
https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-feature-scheduler
https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-whatis
#>

<# We will connect to Azure AD and run a full sync.#>
Import-Module ADSync;
Start-ADSyncCycle Initial;

<# We will connect to Azure AD and run a delta sync.#>
Import-Module ADSync;
Start-ADSyncCycle Delta;

<# We will set some custom sync variables.#>
$time = "d.HH:mm:ss"; # time interval structure. (JEA_20230419)
$time = "0:30:00"; # Setting the time to every 30 minutes. (JEA_20230419)
$time = ""; # Empty value. (JEA_20230419)
Set-ADSyncScheduler -CustomizedSyncCycleInterval $time;

<# Disable Azure AD Sync service.#>
Set-ADSyncScheduler -SyncCycleEnabled $false;

<# Enable Azure AD Sync service.#>
Set-ADSyncScheduler -SyncCycleEnabled $true;

<# We will query Azure AD for a status update.#>
Get-ADSyncConnectorRunStatus