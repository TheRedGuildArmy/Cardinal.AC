param(
  [string]$OutputDir = ".\output",
  [switch]$NoNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# Load modules
Import-Module "$PSScriptRoot\modules\00-Utils.psm1" -Force
Import-Module "$PSScriptRoot\modules\10-System.psm1" -Force
Import-Module "$PSScriptRoot\modules\20-Defender.psm1" -Force
Import-Module "$PSScriptRoot\modules\30-DiscordSafe.psm1" -Force
Import-Module "$PSScriptRoot\modules\40-FilesAndRegistry.psm1" -Force
Import-Module "$PSScriptRoot\modules\50-Prefetch.psm1" -Force
Import-Module "$PSScriptRoot\modules\60-MonitorsEDID.psm1" -Force
Import-Module "$PSScriptRoot\modules\70-PCIDevices.psm1" -Force
Import-Module "$PSScriptRoot\modules\80-Accounts.psm1" -Force
Import-Module "$PSScriptRoot\modules\90-Report.psm1" -Force

# Load config
$configPath = Join-Path $PSScriptRoot "config\config.psd1"
$Config = Import-PowerShellDataFile -Path $configPath

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Ask for display name (kept from original script)
$name = Read-Host -Prompt "Type your name here"
if (-not $name) { $name = $env:USERNAME }

# Network lookups
$allowNetwork = [bool]$Config.EnableNetworkLookups
if ($NoNetwork) { $allowNetwork = $false }

# Consent gate (Y/N) + banner + advisory font
$ok = Show-ConsentGate -ProductName "Cardinal.AC" -OutputDirHint $OutputDir -AllowNetworkLookups:($allowNetwork)
if (-not $ok) {
  Write-Host "Scan cancelled by user."
  exit 0
}

# Timestamped output filenames
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$base = Join-Path $OutputDir ("audit_{0}_{1}" -f $name.Replace(" ", "_"), $ts)

# Collect sections
$context = [ordered]@{
  Timestamp = (Get-Date).ToString("o")
  RequestedBy = $name
  Hostname  = $env:COMPUTERNAME
  User      = $env:USERNAME
  IsAdmin   = Test-IsAdmin
  NetworkLookups = $allowNetwork
}

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
  Monitors = Get-MonitorEdidSection
  PCIe     = Get-PciSection -Config $Config
  Accounts = Get-AccountsSection -AllowNetworkLookups:($allowNetwork) -Config $Config
}

$report["Summary"] = New-SummarySection -Report $report

# Write outputs
Write-JsonReport -Object $report -Path ($base + ".json")
Write-TextReport -Object $report -Path ($base + ".txt")

Write-Host ""
Write-Host "Done."
Write-Host ("TXT:  " + $base + ".txt")
Write-Host ("JSON: " + $base + ".json")
