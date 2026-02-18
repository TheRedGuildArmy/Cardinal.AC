function Get-OneDrivePath {
  $p = (Get-ItemProperty "HKCU:\Software\Microsoft\OneDrive" -Name "UserFolder" -ErrorAction SilentlyContinue).UserFolder
  if ($p -and (Test-Path $p)) { return $p }
  $fallback = Join-Path $env:USERPROFILE "OneDrive"
  if (Test-Path $fallback) { return $fallback }
  return $null
}

function Get-FilesSection {
  param([Parameter(Mandatory=$true)]$Config)

  $oneDrive = Get-OneDrivePath
  $targets = @($Config.ScanTargets + $Config.ExtraScanTargets) | Where-Object { $_ } | Sort-Object -Unique

  # Keep the “rar + exe” concept, but with a reasonable cap
  $rarExeHits = @()
  $susNameHits = @()

  $pattern10 = '^[A-Za-z0-9]{10}\.exe$'

  foreach ($t in $targets) {
    if (-not (Test-Path $t)) { continue }

    $files = Get-ChildItem -Path $t -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1200
    foreach ($f in $files) {
      # rar/exe inventory
      if ($f.Extension -in @(".rar",".exe")) {
        $rarExeHits += [ordered]@{ Path=$f.FullName; LastWrite=$f.LastWriteTime; Size=$f.Length }
      }

      # suspicious names (10-char exe) or configured watch list
      if ($f.Name -match $pattern10) {
        $susNameHits += [ordered]@{ Path=$f.FullName; Why="10char-exe"; LastWrite=$f.LastWriteTime }
      }

      foreach ($w in $Config.WatchFileNames) {
        if ($w -and $f.Name.ToLower().Contains($w.ToLower())) {
          $susNameHits += [ordered]@{ Path=$f.FullName; Why=("watch:" + $w); LastWrite=$f.LastWriteTime }
          break
        }
      }

      foreach ($kw in $Config.SuspiciousKeywords) {
        if ($kw -and ($f.Name.ToLower().Contains($kw.ToLower()) -or $f.FullName.ToLower().Contains($kw.ToLower()))) {
          $susNameHits += [ordered]@{ Path=$f.FullName; Why=("kw:" + $kw); LastWrite=$f.LastWriteTime }
          break
        }
      }
    }
  }

  # Add OneDrive folder note (kept from original behavior)
  return [ordered]@{
    OneDrivePath = $oneDrive
    Targets = $targets
    RarExeCount = $rarExeHits.Count
    RarExe = ($rarExeHits | Sort-Object Path | Select-Object -First 400)
    SusNameCount = $susNameHits.Count
    SusNamed = ($susNameHits | Sort-Object Path -Unique | Select-Object -First 400)
  }
}

function Get-RegistryTraceSection {
  param([Parameter(Mandatory=$true)]$Config)

  $out = [ordered]@{}

  # BAM State UserSettings (machine-wide; often needs admin)
  $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
  $bam = @()

  if (Test-Path $bamPath) {
    try {
      $subs = Get-ChildItem -Path $bamPath -ErrorAction Stop
      foreach ($s in $subs) {
        # NOTE: do not hard-code SID like *1001; enumerate all
        $props = Get-ItemProperty -Path $s.PSPath -ErrorAction SilentlyContinue
        foreach ($p in $props.PSObject.Properties) {
          $n = $p.Name
          if ($n -match "\.exe$" -or $n -match "\.rar$") {
            $bam += [ordered]@{ UserKey=$s.PSChildName; Entry=$n }
          }
        }
      }
    } catch {
      $out["BAM_Note"] = "BAM/UserSettings access denied (run as Admin for full results)."
    }
  } else {
    $out["BAM_Note"] = "BAM/UserSettings path not found."
  }

  # AppCompat compatibility assistant store (per-user)
  $compatPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store"
  $compat = @()
  if (Test-Path $compatPath) {
    $props = Get-ItemProperty -Path $compatPath -ErrorAction SilentlyContinue
    foreach ($p in $props.PSObject.Properties) {
      if ($p.Name -match "\.exe$" -or $p.Name -match "\.rar$") {
        $compat += [ordered]@{ Entry=$p.Name; Value=("$($p.Value)") }
      }
    }
  }

  # FeatureUsage AppSwitched (per-user)
  $appSwitchedPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
  $appSwitched = @()
  if (Test-Path $appSwitchedPath) {
    $props = Get-ItemProperty -Path $appSwitchedPath -ErrorAction SilentlyContinue
    foreach ($p in $props.PSObject.Properties) {
      if ($p.Name -match "\.exe$" -or $p.Name -match "\.rar$") {
        $appSwitched += [ordered]@{ Entry=$p.Name }
      }
    }
  }

  # MuiCache (this hive is tricky; still best-effort)
  $muiPath = "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
  $mui = @()
  if (Test-Path $muiPath) {
    try {
      $props = Get-ItemProperty -Path $muiPath -ErrorAction SilentlyContinue
      foreach ($p in $props.PSObject.Properties) {
        if ($p.Name -match "\.exe" -or $p.Name -match "\.rar") {
          $mui += [ordered]@{ Entry=$p.Name; Value=("$($p.Value)") }
        }
      }
    } catch { }
  }

  # Downloaded browsers via HKLM StartMenuInternet
  $browsers = @()
  $browserKey = "HKLM:\SOFTWARE\Clients\StartMenuInternet"
  if (Test-Path $browserKey) {
    Get-ChildItem -Path $browserKey -ErrorAction SilentlyContinue | ForEach-Object {
      $browsers += $_.PSChildName
    }
  }

  return [ordered]@{
    BAM = ($bam | Sort-Object Entry -Unique | Select-Object -First 400)
    CompatibilityAssistant = ($compat | Sort-Object Entry -Unique | Select-Object -First 200)
    AppSwitched = ($appSwitched | Sort-Object Entry -Unique | Select-Object -First 200)
    MuiCache = ($mui | Sort-Object Entry -Unique | Select-Object -First 200)
    Browsers = ($browsers | Sort-Object -Unique)
    Notes = @(
      "These are Windows execution traces and caches used for auditing. Missing entries do not prove absence."
    )
  }
}

Export-ModuleMember -Function Get-FilesSection, Get-RegistryTraceSection
