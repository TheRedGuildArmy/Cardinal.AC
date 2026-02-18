param(
  [string]$OutputDir = ".\output",
  [switch]$NoNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# -----------------------------
# Load modules
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
# User prompt (kept simple)
# -----------------------------
$name = Read-Host -Prompt "Type your name here"
if (-not $name) { $name = $env:USERNAME }

# Network lookups (VAC/public profile checks only)
$allowNetwork = [bool]$Config.EnableNetworkLookups
if ($NoNetwork) { $allowNetwork = $false }

# -----------------------------
# Consent gate (Y/N)
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

# Summary last (uses report content)
$report["Summary"] = New-SummarySection -Report $report

# -----------------------------
# Write outputs
# -----------------------------
Write-JsonReport -Object $report -Path ($base + ".json")
Write-TextReport -Object $report -Path ($base + ".txt")

Write-Host ""
Write-Host "Done."
Write-Host ("TXT:  " + $base + ".txt")
Write-Host ("JSON: " + $base + ".json")
