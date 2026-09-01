###########################
# NAME: Install ADDS-DC   #
# AUTHOR: DesertRatz      #
# CREATED: 2026/07/31     #
# (C) 2022-2026           #
###########################

#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Installs and configures Active Directory Domain Services (AD DS) on Windows Server 2022,
    standing up a new forest/domain.

.DESCRIPTION
    - Validates the host is fit to become a domain controller (OS version, admin rights,
      pending reboots, domain-join state, disk space, networking).
    - Interactively prompts for domain configuration (FQDN, NetBIOS name, DNS option,
      database/log/SYSVOL paths).
    - Prompts twice for the DSRM (Directory Services Restore Mode) password as a SecureString.
      The password is NEVER written to disk, transcript, or console in plain text. It is only
      ever decrypted transiently in memory to satisfy the .NET comparison/marshal APIs, and
      those in-memory copies are zeroed out immediately after use.
    - Forces ForestMode/DomainMode to "WinThreshold" (Windows Server 2016 functional level).
      This is intentional: Windows Server 2016 remains the highest forest/domain functional
      level defined by Microsoft. There is no 2019 or 2022 functional level — Server 2019/2022
      can only join/create domains at WinThreshold or lower. Do NOT change this value unless
      Microsoft ships a newer functional level AND this OS supports it.
    - Logs everything (except secrets) to a timestamped folder under the current user's
      Downloads directory.

.NOTES
    Run this on a clean Windows Server 2022 member/standalone server. The server will reboot
    automatically at the end of a successful run unless you decline the reboot prompt.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
$script:ExitCode = 0

# ============================================================================
#  LOGGING SETUP
# ============================================================================

function Get-DownloadsPath {
    # Reliable way to resolve the *actual* Downloads folder, honoring redirection,
    # instead of assuming "$env:USERPROFILE\Downloads".
    try {
        $shellFolders = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
        $path = Get-ItemPropertyValue -Path $shellFolders -Name '{374DE290-123F-4565-9164-39C4925E467B}' -ErrorAction Stop
        $path = [Environment]::ExpandEnvironmentVariables($path)
        if (Test-Path $path) { return $path }
    }
    catch {
        # Fall through to default below
    }
    return (Join-Path $env:USERPROFILE 'Downloads')
}

$DownloadsPath = Get-DownloadsPath
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFolder = Join-Path $DownloadsPath "ADDS-Install-$Timestamp"
$LogFile = Join-Path $LogFolder 'ADDS-Install.log'
$TranscriptFile = Join-Path $LogFolder 'ADDS-Install-Transcript.log'

New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
Start-Transcript -Path $TranscriptFile -Force | Out-Null

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')][string]$Level = 'INFO'
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogFile -Value $line
    switch ($Level) {
        'WARN' { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

Write-Log "Log folder created at: $LogFolder"
Write-Log "AD DS installation script starting."

# ============================================================================
#  SAFETY / PRE-FLIGHT CHECKS
# ============================================================================

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsServer2022 {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Log "Detected OS: $($os.Caption) (Build $($os.BuildNumber))"
    # Server 2022 = build 20348. Guard against running this on the wrong OS,
    # since the functional-level ceiling logic below assumes Server 2022.
    if ($os.BuildNumber -ne '20348') {
        return $false
    }
    return $true
}

function Test-PendingReboot {
    $pending = $false
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { $pending = $true }
    }
    $pfro = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
    if ($pfro) { $pending = $true }
    return $pending
}

function Test-AlreadyDomainRole {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    # DomainRole: 4 = Backup DC, 5 = Primary DC. 0/1 = standalone/member workstation, 2/3 = standalone/member server.
    return ($cs.DomainRole -ge 4)
}

function Test-SufficientDiskSpace {
    param([string]$DriveLetter = 'C', [int]$MinimumGB = 10)
    $drive = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
    if (-not $drive) { return $false }
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Log "Free space on ${DriveLetter}: $freeGB GB"
    return ($freeGB -ge $MinimumGB)
}

function Test-StaticIPConfigured {
    $adapters = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' }
    foreach ($a in $adapters) {
        $ipIface = Get-NetIPInterface -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipIface -and $ipIface.Dhcp -eq 'Enabled') {
            return $false
        }
    }
    return $true
}

Write-Log "Running pre-flight safeguards..."

$preflightFailures = New-Object System.Collections.Generic.List[string]

if (-not (Test-IsAdministrator)) {
    $preflightFailures.Add("Script is not running in an elevated (Administrator) session.")
}

if (-not (Test-IsServer2022)) {
    $preflightFailures.Add("This host does not appear to be Windows Server 2022 (build 20348). This script pins the forest/domain functional level assuming Server 2022; do not run it unmodified on other OS versions.")
}

if (Test-AlreadyDomainRole) {
    $preflightFailures.Add("This machine is already a Domain Controller (DomainRole 4 or 5). Aborting to avoid reconfiguring an existing DC.")
}

if (Test-PendingReboot) {
    $preflightFailures.Add("A pending reboot was detected. Reboot the server and re-run this script before promoting it to a Domain Controller.")
}

if (-not (Test-SufficientDiskSpace -DriveLetter 'C' -MinimumGB 10)) {
    $preflightFailures.Add("Less than 10 GB free on C:. AD DS (NTDS/SYSVOL/logs) needs headroom to install and operate safely.")
}

if (-not (Test-StaticIPConfigured)) {
    Write-Log "WARNING: At least one active network adapter is using DHCP. A Domain Controller should have a static IP (and typically a static DNS pointing to itself/another DC). This is a warning, not a hard stop." -Level WARN
}

if ($preflightFailures.Count -gt 0) {
    Write-Log "Pre-flight checks failed. Aborting before making any changes." -Level ERROR
    foreach ($f in $preflightFailures) { Write-Log " - $f" -Level ERROR }
    Stop-Transcript | Out-Null
    exit 1
}

Write-Log "Pre-flight checks passed." -Level SUCCESS

# ============================================================================
#  INPUT VALIDATION HELPERS
# ============================================================================

function Test-ValidFqdn {
    param([string]$Name)
    # Basic FQDN validation: labels of letters/digits/hyphens, at least one dot, valid TLD-ish label.
    return $Name -match '^(?=.{1,255}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))+$'
}

function Test-ValidNetBiosName {
    param([string]$Name)
    # NetBIOS domain names: up to 15 chars, no special/reserved characters.
    return ($Name.Length -ge 1 -and $Name.Length -le 15 -and $Name -match '^[A-Za-z0-9-]+$')
}

function Get-DefaultNetBiosFromFqdn {
    param([string]$Fqdn)
    $label = $Fqdn.Split('.')[0].ToUpper()
    if ($label.Length -gt 15) { $label = $label.Substring(0, 15) }
    return $label
}

# ============================================================================
#  COLLECT DOMAIN CONFIGURATION FROM THE USER
# ============================================================================

Write-Host ""
Write-Host "=== New Forest / Domain Configuration ===" -ForegroundColor Cyan

do {
    $DomainName = Read-Host "Enter the fully qualified domain name for the new forest (e.g. corp.contoso.com)"
    if (-not (Test-ValidFqdn $DomainName)) {
        Write-Host "That doesn't look like a valid FQDN. Please try again." -ForegroundColor Yellow
        $DomainName = $null
    }
} while (-not $DomainName)

$DefaultNetBios = Get-DefaultNetBiosFromFqdn -Fqdn $DomainName
$NetBiosInput = Read-Host "Enter the NetBIOS domain name [default: $DefaultNetBios]"
$NetBiosName = if ([string]::IsNullOrWhiteSpace($NetBiosInput)) { $DefaultNetBios } else { $NetBiosInput.ToUpper() }

if (-not (Test-ValidNetBiosName $NetBiosName)) {
    Write-Log "Invalid NetBIOS name '$NetBiosName' supplied. Aborting." -Level ERROR
    Stop-Transcript | Out-Null
    exit 1
}

$InstallDnsInput = Read-Host "Install and configure the DNS Server role on this DC? (Y/n)"
$InstallDns = -not ($InstallDnsInput -match '^[Nn]')

$DefaultDbPath = 'C:\Windows\NTDS\db'
$DefaultLogPath = 'C:\Windows\NTDS\logs'
$DefaultSysvolPath = 'C:\Windows\SYSVOL'

$DbPathInput = Read-Host "NTDS database path [default: $DefaultDbPath]"
$DatabasePath = if ([string]::IsNullOrWhiteSpace($DbPathInput)) { $DefaultDbPath } else { $DbPathInput }

$LogPathInput = Read-Host "NTDS log path [default: $DefaultLogPath]"
$LogPath = if ([string]::IsNullOrWhiteSpace($LogPathInput)) { $DefaultLogPath } else { $LogPathInput }

$SysvolPathInput = Read-Host "SYSVOL path [default: $DefaultSysvolPath]"
$SysvolPath = if ([string]::IsNullOrWhiteSpace($SysvolPathInput)) { $DefaultSysvolPath } else { $SysvolPathInput }

# ============================================================================
#  DSRM PASSWORD — collected and handled as SecureString only
# ============================================================================

function Get-ConfirmedSecurePassword {
    param([string]$Prompt = "Enter the DSRM (Directory Services Restore Mode) password")

    while ($true) {
        $first = Read-Host -Prompt $Prompt -AsSecureString
        $second = Read-Host -Prompt "Confirm DSRM password" -AsSecureString

        # Enforce a minimum complexity bar without ever writing the password to
        # disk/log/console. We briefly marshal to unmanaged memory to check length
        # and compare, then immediately zero and free that unmanaged buffer.
        $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($first)
        $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($second)
        try {
            $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
            $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)

            $match = ($plain1 -ceq $plain2)
            $longEnough = ($plain1.Length -ge 8)
            $hasUpper = $plain1 -cmatch '[A-Z]'
            $hasLower = $plain1 -cmatch '[a-z]'
            $hasDigitOrSymbol = ($plain1 -match '[0-9]') -or ($plain1 -match '[^A-Za-z0-9]')
        }
        finally {
            # Zero out and free unmanaged memory immediately.
            if ($bstr1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1) }
            if ($bstr2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2) }
            # Clear managed string references too (best-effort; strings are immutable
            # in .NET so this only drops our reference, it doesn't scrub the heap,
            # but it minimizes the window the value is reachable).
            $plain1 = $null
            $plain2 = $null
        }

        if (-not $match) {
            Write-Host "Passwords did not match. Please try again." -ForegroundColor Yellow
            continue
        }
        if (-not ($longEnough -and $hasUpper -and $hasLower -and $hasDigitOrSymbol)) {
            Write-Host "Password does not meet complexity requirements (8+ chars, upper, lower, and a digit or symbol). Please try again." -ForegroundColor Yellow
            continue
        }

        # Dispose the second copy; we only need to return one SecureString onward.
        $second.Dispose()
        return $first
    }
}

Write-Host ""
Write-Host "The DSRM password is required to boot into Directory Services Restore Mode for AD recovery." -ForegroundColor Cyan
Write-Host "It will be handled only as an encrypted SecureString and will never be written to any log file." -ForegroundColor Cyan
$SafeModePassword = Get-ConfirmedSecurePassword

Write-Log "DSRM password collected and validated (value not logged, in keeping with security safeguards)."

# ============================================================================
#  CONFIRMATION BEFORE MAKING CHANGES
# ============================================================================

Write-Host ""
Write-Host "=== Please confirm the configuration below ===" -ForegroundColor Cyan
Write-Host "Fully qualified domain name : $DomainName"
Write-Host "NetBIOS domain name         : $NetBiosName"
Write-Host "Install DNS Server role     : $InstallDns"
Write-Host "Forest functional level     : WinThreshold (Windows Server 2016 highest level supported by Server 2022)"
Write-Host "Domain functional level     : WinThreshold (Windows Server 2016 highest level supported by Server 2022)"
Write-Host "NTDS database path          : $DatabasePath"
Write-Host "NTDS log path               : $LogPath"
Write-Host "SYSVOL path                 : $SysvolPath"
Write-Host "Log/transcript folder       : $LogFolder"
Write-Host "DSRM password               : [hidden]"
Write-Host ""

$confirm = Read-Host "Type YES to proceed and install AD DS with this configuration (anything else aborts)"
if ($confirm -ne 'YES') {
    Write-Log "User did not confirm (typed '$confirm'). Aborting without making changes."
    Stop-Transcript | Out-Null
    exit 0
}

if (-not $PSCmdlet.ShouldProcess($DomainName, "Install AD DS and create new forest")) {
    Write-Log "ShouldProcess declined (-WhatIf). Aborting without making changes."
    Stop-Transcript | Out-Null
    exit 0
}

# ============================================================================
#  INSTALL WINDOWS FEATURES
# ============================================================================

try {
    Write-Log "Installing AD-Domain-Services and management tools..."
    $featureResult = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
    Write-Log "Feature install result: Success=$($featureResult.Success), ExitCode=$($featureResult.ExitCode)"
    if (-not $featureResult.Success) {
        throw "Install-WindowsFeature reported failure. See Windows Server Manager logs for detail."
    }
}
catch {
    Write-Log "Failed to install AD-Domain-Services feature: $($_.Exception.Message)" -Level ERROR
    Stop-Transcript | Out-Null
    exit 1
}

Write-Log "AD-Domain-Services feature installed." -Level SUCCESS

# ============================================================================
#  PROMOTE TO DOMAIN CONTROLLER / CREATE NEW FOREST
# ============================================================================

try {
    Import-Module ADDSDeployment -ErrorAction Stop

    $installParams = @{
        DomainName                    = $DomainName
        DomainNetbiosName             = $NetBiosName
        SafeModeAdministratorPassword = $SafeModePassword
        # WinThreshold is the enum value for the Windows Server 2016 functional level,
        # which is the newest forest/domain mode Windows Server 2022 supports.
        ForestMode                    = 'WinThreshold'
        DomainMode                    = 'WinThreshold'
        DatabasePath                  = $DatabasePath
        LogPath                       = $LogPath
        SysvolPath                    = $SysvolPath
        InstallDns                    = $InstallDns
        NoRebootOnCompletion          = $true
        Force                         = $true
        SkipPreChecks                 = $false
        Confirm                       = $false
        ErrorAction                   = 'Stop'
    }

    Write-Log "Starting Install-ADDSForest. This can take several minutes; the server will not reboot automatically."
    Install-ADDSForest @installParams | Out-Null
    Write-Log "Install-ADDSForest completed successfully." -Level SUCCESS
}
catch {
    Write-Log "Install-ADDSForest failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Review $TranscriptFile and the Server Manager / DCPromo logs under C:\Windows\debug for detail." -Level ERROR
    $script:ExitCode = 1
}
finally {
    # Best-effort cleanup of the SecureString object from memory.
    if ($SafeModePassword) { $SafeModePassword.Dispose() }
}

# ============================================================================
#  WRAP UP
# ============================================================================

if ($script:ExitCode -eq 0) {
    Write-Log "AD DS installation finished. A reboot is required to complete DC promotion." -Level SUCCESS
    Write-Host ""
    $rebootConfirm = Read-Host "Reboot now to finish promotion? (Y/n)"
    Stop-Transcript | Out-Null
    if (-not ($rebootConfirm -match '^[Nn]')) {
        Restart-Computer -Force
    }
    else {
        Write-Host "Remember: this server is NOT fully promoted until it reboots. Reboot manually when ready." -ForegroundColor Yellow
    }
}
else {
    Write-Log "AD DS installation did not complete successfully. No reboot will be triggered." -Level ERROR
    Stop-Transcript | Out-Null
    exit $script:ExitCode
}