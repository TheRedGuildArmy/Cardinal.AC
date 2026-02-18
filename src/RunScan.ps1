param(
  [string]$OutputDir = ".\output",
  [switch]$NoNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ==========================================================
# BOOTSTRAP (so raw-link runs work even with modules)
# If modules aren't present next to this file, download repo zip,
# expand to %TEMP%, then re-run locally from the extracted folder.
# ==========================================================
function Invoke-CardinalBootstrapIfNeeded {
  # If we are not running from a saved file (e.g., iwr | iex),
  # $MyInvocation.MyCommand.Path will be empty, and $PSScriptRoot won't be usable.
  $scriptPath = $MyInvocation.MyCommand.Path
  $isFileRun = [bool]$scriptPath -and (Test-Path $scriptPath)

  if (-not $isFileRun) {
    Write-Host ""
    Write-Host "Cardinal.AC needs its module files. Downloading the full package to TEMP..." -ForegroundColor Yellow

    $zipUrl = "https://github.com/TheRedGuildArmy/Cardinal.AC/archive/refs/heads/main.zip"
    $tempRoot = Join-Path $env:TEMP "CardinalAC_Run"
    $zipPath  = Join-Path $tempRoot "CardinalAC.zip"

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    try {
      Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
      # Clean extract folder
      $extractPath = Join-Path $tempRoot "extract"
      Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
      Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

      # Repo extracts as "Cardinal.AC-main"
      $repoRoot = Join-Path $extractPath "Cardinal.AC-main"
      $localRun = Join-Path $repoRoot "src\RunScan.ps1"

      if (-not (Test-Path $localRun)) {
        Write-Host "Bootstrap failed: couldn't find extracted RunScan.ps1." -ForegroundColor Red
        exit 1
      }

      # Re-run locally (still transparent; user can open the folder and review)
      $argsList = @()
      if ($OutputDir) { $argsList += @("-OutputDir", $OutputDir) }
      if ($NoNetwork) { $argsList += "-NoNetwork" }

      Write-Host "Running local copy: $localRun" -ForegroundColor Green
      & powershell.exe -ExecutionPolicy Bypass -File $localRun @argsList
      exit $LASTEXITCODE
    }
    catch {
      Write-Host "Bootstrap failed: $($_.Exception.Message)" -ForegroundColor Red
      exit 1
    }
  }

  # If we ARE running from file, check for modules folder beside it
  $root = Split-Path -Parent $scriptPath
  $modulesFolder = Join-Path $root "modules"
  if (-not (Test-Path $modulesFolder)) {
    Write-Host "Modules folder not found next to RunScan.ps1: $modulesFolder" -ForegroundColor Red
    Write-Host "Please run from the full repo or let the bootstrap download it." -ForegroundColor Yellow
    exit 1
  }
}

Invoke-CardinalBootstrapIfNeeded

# -----------------------------
# Load modules (local run)
# -----------------------------
Import-Module "$PSScriptRoot\modules\00-Utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\10-System.psm1" -Force
Import-Module "$PSScriptRoot\modules\20-Defender.psm1" -Force
Import-Module "$PSScriptRoot\modules\30-DiscordSafe.psm1" -Force
Import-Module "$PSScriptRoot\modules\40-FilesAndRegistry.psm1" -Force
Import-Module "$PSScriptRoot\modules\50-Prefetch.psm1" -Force
Import-Module "$PSScriptRoot\modules\55-Logitech.psm1" -Force
Import-Module "$PSScriptRoot\modules\60-MonitorsEDID.psm1" -Force
Import-Module "$PSScriptRoot\modules\70-PCIDevices.psm1" -Force
Import-Module "$PSScriptRoot\modules\80-Accounts.psm1" -Force
Import-Module "$PSScriptRoot\modules\90-Report.psm1" -Force

# -----------------------------
# Load config
# -----------------------------
$configPath = Join-Path $PSScriptRoot "config\config.psd1"
$Config = Import-PowerShellDataFile -Path $configPath

# Ensure output folder exists
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# -----------------------------
# Remove "Type your name here"
# Use Windows username (clean + no prompt)
# -----------------------------
$name = $env:USERNAME
if (-not $name) { $name = "User" }

# Network lookups (VAC/public profile checks only)
$allowNetwork = [bool]$Config.EnableNetworkLookups
if ($NoNetwork) { $allowNetwork = $false }

# -----------------------------
# Consent gate (Y/N) — ALWAYS shows now
# -----------------------------
$ok = Show-ConsentGate -ProductName "Cardinal.AC" -OutputDirHint $OutputDir -AllowNetworkLookups:($allowNetwork)
if (-not $ok) {
  Write-Host "Scan cancelled by user."
  exit 0
}

# -----------------------------
# Build output filenames
# -----------------------------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$safeName = $name.Replace(" ", "_")
$base = Join-Path $OutputDir ("audit_{0}_{1}" -f $safeName, $ts)

# -----------------------------
# Context block
# -----------------------------
$context = [ordered]@{
  Timestamp = (Get-Date).ToString("o")
  RequestedBy = $name
  Hostname  = $env:COMPUTERNAME
  User      = $env:USERNAME
  IsAdmin   = Test-IsAdmin
  NetworkLookups = $allowNetwork
}

# -----------------------------
# Collect sections
# -----------------------------
$report = [ordered]@{
  Context  = $context

  System   = Get-SystemSection

  Defender = Get-DefenderSection
  DefenderThreats = Get-DefenderThreatSection
  SystemSecurity  = Get-SystemSecuritySection

  Discord  = Get-DiscordSafeSection

  Files    = Get-FilesSection -Config $Config
  Registry = Get-RegistryTraceSection -Config $Config

  Prefetch = Get-PrefetchSection -Config $Config
  Logitech = Get-LogitechSection

  Monitors = Get-MonitorEdidSection
  PCIe     = Get-PciSection -Config $Config

  Accounts = Get-AccountsSection -AllowNetworkLookups:($allowNetwork) -Config $Config
}

# Summary last
$report["Summary"] = New-SummarySection -Report $report

# -----------------------------
# Write outputs
# -----------------------------
$jsonPath = ($base + ".json")
$txtPath  = ($base + ".txt")

Write-JsonReport -Object $report -Path $jsonPath
Write-TextReport -Object $report -Path $txtPath

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ("TXT:  " + $txtPath)
Write-Host ("JSON: " + $jsonPath)

# -----------------------------
# Auto-open the TXT report
# -----------------------------
try {
  Start-Process -FilePath "notepad.exe" -ArgumentList @("`"$txtPath`"") | Out-Null
} catch {
  # fallback: open with default app
  try { Start-Process -FilePath $txtPath | Out-Null } catch {}
}
