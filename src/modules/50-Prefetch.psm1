function Get-PrefetchSection {
  param([Parameter(Mandatory=$true)]$Config)

  $pf = "$env:SystemRoot\Prefetch"
  if (-not (Test-Path $pf)) {
    return [ordered]@{
      Present = $false
      Path = $pf
      Note = "Prefetch folder not found."
    }
  }

  $max = 400
  try { $max = [int]$Config.PrefetchMaxFiles } catch {}

  # We inventory the .pf files; deep parsing is intentionally not included.
  # (Deep parsing can drift into more forensic/stealth territory and can be error-prone.)
  $items = @()
  try {
    $items = Get-ChildItem -Path $pf -Filter "*.pf" -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First $max Name, FullName, LastWriteTime, Length
  } catch {}

  return [ordered]@{
    Present = $true
    Path = $pf
    Count = $items.Count
    RecentPrefetchFiles = $items
    Note = "Admin recommended for full Prefetch visibility. This section inventories .pf files only."
  }
}

Export-ModuleMember -Function Get-PrefetchSection
