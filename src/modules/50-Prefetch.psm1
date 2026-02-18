function Get-PrefetchSection {
  param([Parameter(Mandatory=$true)]$Config)

  # Prefetch typically requires admin to read reliably.
  $pf = "$env:WINDIR\Prefetch"
  if (-not (Test-Path $pf)) {
    return [ordered]@{ Present=$false; Path=$pf; Note="Prefetch folder not found." }
  }

  $max = [int]$Config.PrefetchMaxFiles
  $items = Get-ChildItem $pf -Filter "*.pf" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $max Name, FullName, LastWriteTime, Length

  [ordered]@{
    Present = $true
    Path = $pf
    Count = $items.Count
    RecentPrefetchFiles = $items
    Note = "This inventories Prefetch .pf files; deeper parsing is intentionally not included for safety/simplicity."
  }
}

Export-ModuleMember -Function Get-PrefetchSection
