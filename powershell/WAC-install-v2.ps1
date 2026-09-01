###########################
# NAME: WAC Installer     #
# AUTHOR: DesertRatz      #
# CREATED: 2026/07/31     #
# (C) 2024-2026           #
###########################

# =========================
# WINDOWS ADMIN CENTER - STANDALONE INSTALL
# Works on Server Core 2022 (with or without AD DS installed)
# =========================

[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int] $Port = 443
)

$ErrorActionPreference = "Stop"

# --- Logging ---
$LogFile = Join-Path $env:USERPROFILE "Downloads\WAC-Standalone-Install.log"
Start-Transcript -Path $LogFile -Force | Out-Null

# --- Paths / Installer ---
$DownloadDir = Join-Path $env:USERPROFILE "Downloads"
$Installer = Join-Path $DownloadDir "WAC.exe"

function Write-Stage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Cyan', 'Yellow', 'Green', 'Red')][string]$Color = 'Cyan'
    )
    Write-Host $Message -ForegroundColor $Color
}

# =========================
# SAFE CLEANUP (fresh VM compatible)
# =========================
function Clean-WAC {
    Write-Stage "Cleaning any existing WAC state..." Yellow

    $svc = Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service WindowsAdminCenter -Force -ErrorAction SilentlyContinue | Out-Null
        sc.exe delete WindowsAdminCenter | Out-Null
    }

    $paths = @(
        "C:\Program Files\WindowsAdminCenter",
        "C:\Program Files\Windows Admin Center",
        "C:\ProgramData\WindowsAdminCenter",
        "C:\ProgramData\Windows Admin Center"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # Best-effort cleanup of stale HTTP.SYS URL ACL (can block rebinding)
    # Best-effort: don't hard-fail if netsh isn't available or no matching ACL exists.
    try {
        $netshShow = netsh http show urlacl 2>$null | Out-String
        if ($netshShow -match ":\s*$Port") {
            netsh http delete urlacl "http://+:$Port/" 2>$null | Out-Null
        }
    }
    catch { }

    # Note: we do NOT remove IIS/AD DS artifacts; only WAC-related directories/service.
}

# =========================
# PREREQS (no AD DS dependency)
# =========================
function Install-Prereqs {
    Write-Stage "Installing prerequisites..." Cyan

    if (-not (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue)) {
        throw "Install-WindowsFeature cmdlet not available. Use a Windows Server image with ServerManager tools."
    }

    Install-WindowsFeature Web-Server -IncludeManagementTools | Out-Null
    Install-WindowsFeature Web-WebSockets | Out-Null
    Install-WindowsFeature NET-Framework-45-Core | Out-Null

    # Enable WinRM for local management
    Enable-PSRemoting -Force | Out-Null
    winrm quickconfig -q | Out-Null

    if (-not (Test-WSMan localhost -ErrorAction SilentlyContinue)) {
        throw "WinRM failed to initialize"
    }
}

# =========================
# FIREWALL (local-only, inbound to chosen port)
# =========================
function Setup-Firewall {
    Write-Stage "Configuring firewall..." Cyan

    New-NetFirewallRule `
        -DisplayName "Windows Admin Center HTTPS (Port $Port)" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $Port `
        -Action Allow `
        -ErrorAction SilentlyContinue | Out-Null
}

# =========================
# DOWNLOAD WAC
# =========================
function Download-WAC {
    Write-Stage "Downloading Windows Admin Center..." Cyan

    if (!(Test-Path $DownloadDir)) {
        New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    }

    if (-not (Test-Path $Installer)) {
        Invoke-WebRequest "https://aka.ms/WACdownload" -OutFile $Installer
    }

    if (!(Test-Path $Installer)) {
        throw "WAC download failed (installer not found)."
    }

    # Basic sanity check: file should be reasonably sized
    $lenBytes = (Get-Item $Installer).Length
    if ($lenBytes -lt 10MB) {
        throw "WAC download appears too small ($lenBytes bytes)."
    }
}

# =========================
# INSTALL WAC (port-safe precheck)
# =========================
function Install-WAC {
    Write-Stage "Installing WAC..." Cyan

    # Fail fast if something already listens on the chosen port.
    $listenerConn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $Port } |
    Select-Object -First 1

    if ($listenerConn) {
        $owningProcessId = $listenerConn.OwningProcess
        $proc = Get-Process -Id $owningProcessId -ErrorAction SilentlyContinue |
        Select-Object -First 1

        throw "Port $Port is already in use (PID $owningProcessId`: $($proc?.ProcessName)). Resolve the conflict or change -Port."
    }

    Start-Process $Installer -ArgumentList @(
        "/VERYSILENT",
        "/NORESTART",
        "/PORT=$Port",
        "/SSL_CERTIFICATE_OPTION=generate"
    ) -Wait -NoNewWindow

    Start-Sleep 2
}

# =========================
# DETECT AD DS (safeguard / info only)
# =========================
function Get-IsADDSInstalled {
    try {
        $adFeature = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue
        if ($adFeature -and $adFeature.Installed) { return $true }
    }
    catch { }

    $adProcs = @("ntdsd", "dns", "dnsserver", "kdc", "netlogon")
    foreach ($p in $adProcs) {
        if (Get-Process -Name $p -ErrorAction SilentlyContinue) { return $true }
    }

    return $false
}

# =========================
# VALIDATION (service + WinRM + binding)
# =========================
function Validate-WAC {
    Write-Stage "Validating WAC installation..." Cyan

    $svc = Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue
    if (-not $svc) {
        throw "WAC service not found"
    }

    if ($svc.Status -ne 'Running') {
        Start-Service WindowsAdminCenter -ErrorAction SilentlyContinue | Out-Null
    }

    # Wait up to ~2 minutes for Running
    $deadline = (Get-Date).AddMinutes(2)
    while ((Get-Date) -lt $deadline) {
        $svc = Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') { break }
        Start-Sleep 2
    }

    $svc = Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue
    if (-not $svc -or $svc.Status -ne 'Running') {
        Write-Stage "WAC service is not running yet." Yellow
        throw "WAC service failed to reach Running state."
    }

    # WinRM check
    if (-not (Test-WSMan localhost -ErrorAction SilentlyContinue)) {
        throw "WinRM not responding"
    }

    # Binding check on port
    $isListening = $false
    $tcp = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $Port } |
    Select-Object -First 1
    if ($tcp) { $isListening = $true }

    if (-not $isListening) {
        throw "WAC did not bind to HTTPS port $Port (bootstrap failure)."
    }

    # Best-effort HTTPS reachability (don't fail if tooling isn't available)
    try {
        $testDeadline = (Get-Date).AddSeconds(30)
        $ok = $false
        while ((Get-Date) -lt $testDeadline -and -not $ok) {
            try {
                $null = Invoke-WebRequest -UseBasicParsing -Method Head `
                    -Uri "https://localhost:$Port" -TimeoutSec 5 -SkipCertificateCheck
                $ok = $true
            }
            catch {
                Start-Sleep 3
            }
        }
        if (-not $ok) {
            Write-Stage "Port $Port is listening but HTTPS HEAD did not succeed yet." Yellow
        }
    }
    catch { }

    if (Get-IsADDSInstalled) {
        Write-Stage "AD DS detected on this server; WAC service is running and port $Port is bound." Green
    }
    else {
        Write-Stage "WAC is fully operational." Green
    }
}

# =========================
# MAIN
# =========================
try {
    Clean-WAC
    Install-Prereqs
    Setup-Firewall
    Download-WAC
    Install-WAC
    Validate-WAC
}
catch {
    Write-Stage "INSTALL FAILED: $($_.Exception.Message)" Red
    Write-Stage "Cleaning and retrying..." Yellow

    try {
        Clean-WAC
        Install-Prereqs
        Setup-Firewall
        Download-WAC
        Install-WAC
        Validate-WAC
    }
    catch {
        Write-Stage "FATAL ERROR: WAC failed twice. Check logs." Red
        throw
    }
}
finally {
    Stop-Transcript | Out-Null
}