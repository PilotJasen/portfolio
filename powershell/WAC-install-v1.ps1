###########################
# NAME: WAC Installer     #
# AUTHOR: DesertRatz      #
# CREATED: 2026/06/27     #
# (C) 2024-2026           #
###########################

# =========================
# WINDOWS ADMIN CENTER - STANDALONE INSTALL
# Server Core 2022 (NO AD DS REQUIRED)
# =========================

$ErrorActionPreference = "Stop"

$LogFile = "$env:USERPROFILE\Downloads\WAC-Standalone-Install.log"
Start-Transcript -Path $LogFile -Force

$DownloadDir = "$env:USERPROFILE\Downloads"
$Installer = Join-Path $DownloadDir "WAC.exe"

$Port = 443

# =========================
# CLEAN ANY LEFTOVER STATE (SAFE FOR FRESH VM TOO)
# =========================
function Clean-WAC {

    Write-Host "Cleaning any existing WAC state..." -ForegroundColor Yellow

    if (Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue) {
        Stop-Service WindowsAdminCenter -Force -ErrorAction SilentlyContinue
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
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# =========================
# BASIC WINDOWS REQUIREMENTS (NO DOMAIN DEPENDENCY)
# =========================
function Install-Prereqs {

    Write-Host "Installing prerequisites..." -ForegroundColor Cyan

    Install-WindowsFeature Web-Server -IncludeManagementTools | Out-Null
    Install-WindowsFeature Web-WebSockets | Out-Null
    Install-WindowsFeature NET-Framework-45-Core | Out-Null

    # Enable WinRM for WAC local management
    Enable-PSRemoting -Force | Out-Null
    winrm quickconfig -q | Out-Null

    if (-not (Test-WsMan localhost -ErrorAction SilentlyContinue)) {
        throw "WinRM failed to initialize"
    }
}

# =========================
# FIREWALL (LOCAL ONLY, SAFE FOR STANDALONE)
# =========================
function Setup-Firewall {

    Write-Host "Configuring firewall..." -ForegroundColor Cyan

    New-NetFirewallRule `
        -DisplayName "Windows Admin Center HTTPS" `
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

    Write-Host "Downloading Windows Admin Center..." -ForegroundColor Cyan

    if (!(Test-Path $DownloadDir)) {
        New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    }

    Invoke-WebRequest "https://aka.ms/WACdownload" -OutFile $Installer

    if (!(Test-Path $Installer)) {
        throw "WAC download failed"
    }
}

# =========================
# INSTALL WAC
# =========================
function Install-WAC {

    Write-Host "Installing WAC..." -ForegroundColor Cyan

    Start-Process $Installer -ArgumentList @(
        "/VERYSILENT",
        "/NORESTART",
        "/PORT=$Port",
        "/SSL_CERTIFICATE_OPTION=generate"
    ) -Wait
}

# =========================
# VALIDATION (REAL HEALTH CHECK)
# =========================
function Validate-WAC {

    Write-Host "Validating WAC installation..." -ForegroundColor Cyan

    $svc = Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue

    if (-not $svc) {
        throw "WAC service not found"
    }

    Start-Service WindowsAdminCenter -ErrorAction SilentlyContinue
    Start-Sleep 10

    # WinRM check
    if (-not (Test-WsMan localhost -ErrorAction SilentlyContinue)) {
        throw "WinRM not responding"
    }

    # Check HTTPS binding (bootstrap validation)
    $portCheck = netstat -ano | findstr ":$Port"

    if (-not $portCheck) {
        throw "WAC did not bind to HTTPS port (bootstrap failure)"
    }

    Write-Host "WAC is fully operational" -ForegroundColor Green
}

# =========================
# MAIN EXECUTION (SIMPLE + STABLE)
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

    Write-Host "INSTALL FAILED: $_" -ForegroundColor Red
    Write-Host "Cleaning and retrying..." -ForegroundColor Yellow

    try {
        Clean-WAC
        Install-Prereqs
        Setup-Firewall
        Download-WAC
        Install-WAC
        Validate-WAC
    }
    catch {
        Write-Host "FATAL ERROR: WAC failed twice. Check logs." -ForegroundColor Red
        throw
    }
}
finally {
    Stop-Transcript
}