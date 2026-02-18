param(
  [string]$OutputDir = ".\output",
  [switch]$NoNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# --- Load modules (organized like a real project) ---
Import-Module "$PSScriptRoot\modules\00-Utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\10-System.psm1" -Force
Import-Module "$PSScriptRoot\modules\20-Defender.psm1" -Force
Import-Module "$PSScriptRoot\modules\30-DiscordSafe.psm1" -Force
Import-Module "$PSScriptRoot\modules\40-CheatsAndScripts.psm1" -Force
Import-Module "$PSScriptRoot\modules\50-Prefetch.psm1" -Force
Import-Module "$PSScriptRoot\modules\60-MonitorsEDID.psm1" -Force
Import-Module "$PSScriptRoot\modules\70-PCIDevices.psm1" -Force
Import-Module "$PSScriptRoot\modules\80-SteamUbisoft.psm1" -Force
Import-Module "$PSScriptRoot\modules\90-Report.psm1" -Force

# --- Load config ---
$configPath = Join-Path $PSScriptRoot "config\config.psd1"
$Config = Import-PowerShellDataFile -Path $configPath

# --- Output folder ---
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$base = Join-Path $OutputDir "audit_$ts"

# --- Decide network behavior ---
$allowNetwork = [bool]$Config.EnableNetworkLookups
if ($NoNetwork) { $allowNetwork = $false }

# --- Consent gate (Y/N) + banner + advisory font ---
$ok = Show-ConsentGate -ProductName "Cardinal.AC" -OutputDirHint $OutputDir -AllowNetworkLookups:($allowNetwork)
if (-not $ok) {
  Write-Host "Scan cancelled by user."
  exit 0
}

# --- Collect scan context ---
$context = [ordered]@{
  Timestamp = (Get-Date).ToString("o")
  Hostname  = $env:COMPUTERNAME
  User      = $env:USERNAME
  IsAdmin   = Test-IsAdmin
  NetworkLookups = $allowNetwork
}

# --- Run collectors (each module does one job) ---
$system   = Get-SystemSection
$defender = Get-DefenderSection
$discord  = Get-DiscordSafeSection
$files    = Get-CheatScriptSection -Config $Config
$prefetch = Get-PrefetchSection -Config $Config
$monitors = Get-MonitorEdidSection
$pcie     = Get-PciSection -Config $Config
$accounts = Get-AccountsSection -AllowNetworkLookups:$allowNetwork

# --- Build report object ---
$report = [ordered]@{
  Context  = $context
  System   = $system
  Defender = $defender
  Discord  = $discord
  Files    = $files
  Prefetch = $prefetch
  Monitors = $monitors
  PCIe     = $pcie
  Accounts = $accounts
  Summary  = New-SummarySection -Report $null  # filled after
}

# Summary uses report content; set it after building
$report.Summary = New-SummarySection -Report $report

# --- Write outputs ---
Write-JsonReport -Object $report -Path ($base + ".json")
Write-TextReport -Object $report -Path ($base + ".txt")

Write-Host ""
Write-Host "Done."
Write-Host ("TXT:  " + $base + ".txt")
Write-Host ("JSON: " + $base + ".json")
