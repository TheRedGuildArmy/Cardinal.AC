function Get-CheatScriptSection {
  param([Parameter(Mandatory=$true)]$Config)

  $targets = @($Config.ScanTargets + $Config.ExtraScanTargets) | Where-Object { $_ } | Sort-Object -Unique

  $hits = @()

  foreach ($t in $targets) {
    if (-not (Test-Path $t)) { continue }

    # NOTE: We intentionally cap recursion by sampling.
    # If you want deeper scans, expand this carefully (can get slow).
    $files = Get-ChildItem $t -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 400

    foreach ($f in $files) {
      $why = @()

      foreach ($ext in $Config.SuspiciousExtensions) {
        if ($f.Name.ToLower().EndsWith($ext.ToLower())) { $why += "ext:$ext"; break }
      }

      foreach ($kw in $Config.SuspiciousKeywords) {
        if ($f.Name.ToLower().Contains($kw.ToLower()) -or $f.FullName.ToLower().Contains($kw.ToLower())) {
          $why += "kw:$kw"; break
        }
      }

      foreach ($name in $Config.WatchFileNames) {
        if ($f.Name.ToLower().Contains($name.ToLower())) {
          $why += "watch:$name"; break
        }
      }

      if ($why.Count -gt 0) {
        $hits += [ordered]@{
          File = $f.FullName
          LastWriteTime = $f.LastWriteTime
          Size = $f.Length
          Why = ($why | Select-Object -Unique)
        }
      }
    }
  }

  [ordered]@{
    Targets = $targets
    HitCount = $hits.Count
    Hits = $hits | Select-Object -First 300
  }
}

Export-ModuleMember -Function Get-CheatScriptSection
