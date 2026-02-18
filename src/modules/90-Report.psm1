function Write-JsonReport {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)
  ($Object | ConvertTo-Json -Depth 12) | Set-Content -Path $Path -Encoding UTF8
}

function Add-Section {
  param(
    [System.Collections.Generic.List[string]]$Lines,
    [string]$Title
  )
  $Lines.Add("")
  $Lines.Add(("=" * 78))
  $Lines.Add($Title)
  $Lines.Add(("=" * 78))
}

function New-SummarySection {
  param([Parameter(Mandatory)]$Report)

  $sum = @()
  $sum += "Suspicious file/name hits: $($Report.Files.SusNameCount)"
  $sum += "RAR/EXE inventory hits: $($Report.Files.RarExeCount)"
  $sum += "Discord running: $($Report.Discord.DiscordRunning) (safe checks only)"
  $sum += "Defender present: $($Report.Defender.Present)"
  if ($Report.Defender.Present) { $sum += "Defender enabled: $($Report.Defender.AntivirusEnabled)" }
  $sum += "Prefetch files inventoried: $($Report.Prefetch.Count)"
  $sum += "Monitors found: $($Report.Monitors.Count)"
  $sum += "PCIe hints: $($Report.PCIe.SuspiciousHints.Count)"
  $sum += "Steam IDs found: $($Report.Accounts.Steam.SteamIds.Count)"
  if (-not $Report.Context.NetworkLookups) { $sum += "VAC checks skipped (network disabled)" }
  return $sum
}

function Write-TextReport {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)

  $L = New-Object System.Collections.Generic.List[string]

  $L.Add("Cardinal.AC - Audit Report")
  $L.Add("Timestamp: $($Object.Context.Timestamp)")
  $L.Add("RequestedBy: $($Object.Context.RequestedBy)")
  $L.Add("Host: $($Object.Context.Hostname)  User: $($Object.Context.User)  Admin: $($Object.Context.IsAdmin)")
  $L.Add("NetworkLookups: $($Object.Context.NetworkLookups)")

  Add-Section $L "SUMMARY"
  foreach ($s in $Object.Summary) { $L.Add("- " + $s) }

  Add-Section $L "SYSTEM"
  $L.Add("OS: $($Object.System.OS.Caption)")
  $L.Add("Version: $($Object.System.OS.Version)  Build: $($Object.System.OS.Build)  Arch: $($Object.System.OS.Arch)")
  $L.Add("InstallDate: $($Object.System.OS.InstallDate)")
  $L.Add("CPU: $($Object.System.CPU)")
  $L.Add("RAM(GB): $($Object.System.RAM_GB)")

  Add-Section $L "WINDOWS DEFENDER"
  $def = $Object.Defender
  $L.Add("Present: $($def.Present)")
  if ($def.Present) {
    $L.Add("AntivirusEnabled: $($def.AntivirusEnabled)")
    $L.Add("RealTimeProtectionEnabled: $($def.RealTimeProtectionEnabled)")
    $L.Add("TamperProtection: $($def.TamperProtection)")
    $L.Add("FirewallEnabled: $($def.FirewallEnabled)")
    $L.Add("AntispywareEnabled: $($def.AntispywareEnabled)")
    $L.Add("QuickScanAgeDays: $($def.QuickScanAgeDays)")
    $L.Add("FullScanAgeDays: $($def.FullScanAgeDays)")
  } else {
    $L.Add("Note: $($def.Note)")
  }

  Add-Section $L "DEFENDER THREATS (BEST EFFORT)"
  $L.Add("Count: $($Object.DefenderThreats.Count)")
  foreach ($t in $Object.DefenderThreats.Items) {
    $L.Add(" - $($t.ThreatName) | Severity:$($t.SeverityID) | ActionSuccess:$($t.ActionSuccess)")
    if ($t.ExecutionPath) { $L.Add("   Path: $($t.ExecutionPath)") }
  }

  Add-Section $L "SYSTEM SECURITY"
  $sec = $Object.SystemSecurity
  $L.Add("SecureBoot: $($sec.SecureBoot)")
  $L.Add("KernelDmaProtection: $($sec.KernelDmaProtection)")
  $L.Add("AllowedBusesKeyCount: $($sec.AllowedBuses.Count)")
  if ($sec.AllowedBuses.Count -gt 0) {
    foreach ($k in $sec.AllowedBuses) { $L.Add(" - " + $k) }
  } else {
    if ($sec.AllowedBusesNote) { $L.Add("Note: $($sec.AllowedBusesNote)") }
  }

  Add-Section $L "DISCORD (SAFE CHECKS)"
  $dc = $Object.Discord
  $L.Add("DiscordRunning: $($dc.DiscordRunning)")
  $L.Add("InstallPaths: " + (($dc.InstallPaths -join "; ")))
  $L.Add("ModIndicators: " + (($dc.ModIndicators -join ", ")))
  $L.Add("Note: $($dc.Note)")

  Add-Section $L "FILES (RAR/EXE INVENTORY + HEURISTIC HITS)"
  $L.Add("OneDrivePath: $($Object.Files.OneDrivePath)")
  $L.Add("Targets: " + (($Object.Files.Targets -join "; ")))
  $L.Add("RAR/EXE count: $($Object.Files.RarExeCount)")
  foreach ($h in $Object.Files.RarExe) {
    $L.Add(" - $($h.Path) | $($h.LastWrite)")
  }

  $L.Add("")
  $L.Add("Suspicious name/keyword hits: $($Object.Files.SusNameCount)")
  foreach ($h in $Object.Files.SusNamed) {
    $L.Add(" - $($h.Path) | $($h.Why) | $($h.LastWrite)")
  }

  Add-Section $L "REGISTRY EXECUTION TRACES (BEST EFFORT)"
  $r = $Object.Registry
  $L.Add("BAM entries: $($r.BAM.Count)")
  foreach ($e in ($r.BAM | Select-Object -First 120)) { $L.Add(" - $($e.UserKey): $($e.Entry)") }

  $L.Add("")
  $L.Add("CompatibilityAssistant entries: $($r.CompatibilityAssistant.Count)")
  foreach ($e in ($r.CompatibilityAssistant | Select-Object -First 80)) { $L.Add(" - $($e.Entry)") }

  $L.Add("")
  $L.Add("AppSwitched entries: $($r.AppSwitched.Count)")
  foreach ($e in ($r.AppSwitched | Select-Object -First 80)) { $L.Add(" - $($e.Entry)") }

  $L.Add("")
  $L.Add("MuiCache entries: $($r.MuiCache.Count)")
  foreach ($e in ($r.MuiCache | Select-Object -First 80)) { $L.Add(" - $($e.Entry)") }

  $L.Add("")
  $L.Add("Browsers: " + (($r.Browsers -join ", ")))

  Add-Section $L "PREFETCH"
  $pf = $Object.Prefetch
  $L.Add("Present: $($pf.Present) | Path: $($pf.Path) | Count: $($pf.Count)")
  $L.Add("Note: $($pf.Note)")
  foreach ($p in ($pf.RecentPrefetchFiles | Select-Object -First 60)) {
    $L.Add(" - $($p.Name) | $($p.LastWriteTime)")
  }

  Add-Section $L "MONITORS / EDID"
  $L.Add("MonitorCount: $($Object.Monitors.Count)")
  foreach ($m in $Object.Monitors.Items) {
    $L.Add(" - $($m.Manufacturer) | $($m.Name) | Serial:$($m.Serial) | Y:$($m.Year) W:$($m.Week)")
  }

  Add-Section $L "PCIe DEVICES"
  $L.Add("DeviceCount: $($Object.PCIe.Count)")
  $L.Add("SuspiciousHintsCount: $($Object.PCIe.SuspiciousHints.Count)")
  foreach ($x in $Object.PCIe.SuspiciousHints) {
    $L.Add(" - $($x.Name) | [$($x.Why -join ', ')] | $($x.PNPDeviceID)")
  }

  Add-Section $L "ACCOUNTS (STEAM / UBISOFT)"
  $acc = $Object.Accounts
  $L.Add("Steam Found: $($acc.Steam.Found)")
  if ($acc.Steam.Found) {
    $L.Add("Steam VDF: $($acc.Steam.Path)")
    $L.Add("SteamIDs: " + (($acc.Steam.SteamIds -join ", ")))
    if ($acc.Steam.VacChecks.Count -gt 0) {
      foreach ($c in $acc.Steam.VacChecks) {
        $L.Add(" - $($c.SteamId64): VAC=$($c.Vac.VacBanMarker) GAMEBAN=$($c.Vac.GameBanMarker) COMMUNITYBAN=$($c.Vac.CommunityBanMarker) Checked=$($c.Vac.Checked)")
      }
    } else {
      if ($acc.Steam.Note) { $L.Add("Note: $($acc.Steam.Note)") }
    }
  }

  $L.Add("Ubisoft Present: $($acc.Ubisoft.Present)")
  if ($acc.Ubisoft.Present) { $L.Add("Ubisoft Path: $($acc.Ubisoft.Path)") }

  $L | Set-Content -Path $Path -Encoding UTF8
}

Export-ModuleMember -Function Write-JsonReport, Write-TextReport, New-SummarySection
