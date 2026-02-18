function Write-JsonReport {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)
  ($Object | ConvertTo-Json -Depth 10) | Set-Content -Path $Path -Encoding UTF8
}

function Add-Section {
  param([System.Collections.Generic.List[string]]$Lines, [string]$Title)
  $Lines.Add("")
  $Lines.Add(("=" * 70))
  $Lines.Add($Title)
  $Lines.Add(("=" * 70))
}

function Write-TextReport {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)

  $L = New-Object System.Collections.Generic.List[string]

  $L.Add("Cardinal.AC - Audit Report")
  $L.Add("Timestamp: $($Object.Context.Timestamp)")
  $L.Add("Host: $($Object.Context.Hostname)  User: $($Object.Context.User)  Admin: $($Object.Context.IsAdmin)")
  $L.Add("NetworkLookups: $($Object.Context.NetworkLookups)")

  Add-Section -Lines $L -Title "SUMMARY"
  foreach ($s in $Object.Summary) { $L.Add("- " + $s) }

  Add-Section -Lines $L -Title "WINDOWS / SYSTEM"
  $L.Add("OS: $($Object.System.OS.Caption)  Build: $($Object.System.OS.Build)  Arch: $($Object.System.OS.Arch)")
  $L.Add("CPU: $($Object.System.CPU)")
  $L.Add("RAM(GB): $($Object.System.RAM_GB)")

  Add-Section -Lines $L -Title "WINDOWS DEFENDER"
  $def = $Object.Defender
  $L.Add("Defender Present: $($def.Present)")
  if ($def.Present) {
    $L.Add("AntivirusEnabled: $($def.AntivirusEnabled)")
    $L.Add("RealTimeProtectionEnabled: $($def.RealTimeProtectionEnabled)")
    $L.Add("TamperProtection: $($def.TamperProtection)")
  } else {
    $L.Add("Note: $($def.Note)")
  }

  Add-Section -Lines $L -Title "DISCORD (SAFE CHECKS)"
  $dc = $Object.Discord
  $L.Add("DiscordRunning: $($dc.DiscordRunning)")
  $L.Add("InstallPaths: " + (($dc.InstallPaths -join "; ")))
  $L.Add("ModIndicators: " + (($dc.ModIndicators -join ", ")))
  $L.Add("Note: $($dc.Note)")

  Add-Section -Lines $L -Title "CHEAT / SCRIPT / DMA ARTIFACTS (HEURISTICS)"
  $L.Add("Targets: " + (($Object.Files.Targets -join "; ")))
  $L.Add("HitCount: $($Object.Files.HitCount)")
  foreach ($h in $Object.Files.Hits) {
    $L.Add(" - $($h.File)  [$($h.Why -join ', ')]")
  }

  Add-Section -Lines $L -Title "PREFETCH"
  $pf = $Object.Prefetch
  $L.Add("Present: $($pf.Present)  Path: $($pf.Path)")
  $L.Add("Count: $($pf.Count)")
  $L.Add("Note: $($pf.Note)")
  foreach ($p in ($pf.RecentPrefetchFiles | Select-Object -First 40)) {
    $L.Add(" - $($p.Name)  $($p.LastWriteTime)")
  }

  Add-Section -Lines $L -Title "MONITORS / EDID"
  $L.Add("MonitorCount: $($Object.Monitors.Count)")
  foreach ($m in $Object.Monitors.Items) {
    $L.Add(" - $($m.Manufacturer) | $($m.Name) | Serial:$($m.Serial) | Y:$($m.Year) W:$($m.Week)")
  }

  Add-Section -Lines $L -Title "PCIe DEVICES"
  $L.Add("DeviceCount: $($Object.PCIe.Count)")
  $L.Add("SuspiciousHintsCount: $($Object.PCIe.SuspiciousHints.Count)")
  foreach ($x in $Object.PCIe.SuspiciousHints) {
    $L.Add(" - $($x.Name)  [$($x.Why -join ', ')]  $($x.PNPDeviceID)")
  }

  Add-Section -Lines $L -Title "ACCOUNTS (STEAM / UBISOFT)"
  $acc = $Object.Accounts
  $L.Add("Steam Found: $($acc.Steam.Found)")
  if ($acc.Steam.Found) {
    $L.Add("Steam VDF: $($acc.Steam.Path)")
    $L.Add("SteamIDs: " + (($acc.Steam.SteamIds -join ", ")))
    if ($acc.Steam.VacChecks.Count -gt 0) {
      foreach ($c in $acc.Steam.VacChecks) {
        $L.Add(" - $($c.SteamId64): VAC=$($c.Vac.VacBanMarker) GAMEBAN=$($c.Vac.GameBanMarker) Checked=$($c.Vac.Checked)")
      }
    } else {
      if ($acc.Steam.Note) { $L.Add("Note: $($acc.Steam.Note)") }
    }
  }

  $L.Add("Ubisoft Present: $($acc.Ubisoft.Present)")
  if ($acc.Ubisoft.Present) { $L.Add("Ubisoft Path: $($acc.Ubisoft.Path)") }

  $L | Set-Content -Path $Path -Encoding UTF8
}

function New-SummarySection {
  param([Parameter(Mandatory)]$Report)

  # Beginner-friendly summary bullets
  $sum = @()
  $sum += "Cheat/script artifact hits: $($Report.Files.HitCount)"
  $sum += "Discord running: $($Report.Discord.DiscordRunning) (safe checks only)"
  $sum += "Defender enabled: $($Report.Defender.AntivirusEnabled)"
  $sum += "Prefetch files scanned: $($Report.Prefetch.Count)"
  $sum += "Monitors found: $($Report.Monitors.Count)"
  $sum += "PCIe suspicious hints: $($Report.PCIe.SuspiciousHints.Count)"
  $sum += "Steam accounts found: $($Report.Accounts.Steam.SteamIds.Count)"
  if (-not $Report.Context.NetworkLookups) { $sum += "VAC checks skipped (network disabled)" }
  return $sum
}

Export-ModuleMember -Function Write-JsonReport, Write-TextReport, New-SummarySection
