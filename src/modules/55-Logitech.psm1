function Get-LogitechSection {

  # Audits Logitech G HUB / LGS script locations.
  # This does NOT execute scripts.
  # It only inventories files for transparency.

  $hits = @()

  # Logitech G HUB scripts folder
  $ghubScripts = Join-Path $env:LOCALAPPDATA "LGHUB\scripts"

  # Older Logitech Gaming Software folders
  $lgsPaths = @(
    Join-Path $env:APPDATA "Logitech",
    Join-Path $env:LOCALAPPDATA "Logitech"
  )

  function Add-FilesFromFolder {
    param([string]$Folder, [string]$Label)

    if (-not (Test-Path $Folder)) { return }

    try {
      $files = Get-ChildItem -Path $Folder -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 250

      foreach ($f in $files) {
        $hits += [ordered]@{
          Source = $Label
          Path = $f.FullName
          LastWriteTime = $f.LastWriteTime
          SizeBytes = $f.Length
        }
      }
    } catch {
      $hits += [ordered]@{
        Source = $Label
        Path = $Folder
        Note = "Error listing folder."
      }
    }
  }

  Add-FilesFromFolder -Folder $ghubScripts -Label "LGHUB Scripts"

  foreach ($p in $lgsPaths) {
    Add-FilesFromFolder -Folder $p -Label "Logitech AppData"
  }

  return [ordered]@{
    GHubScriptsPath = $ghubScripts
    CheckedPaths = @($ghubScripts) + $lgsPaths
    HitCount = $hits.Count
    Files = $hits
    Note = "Presence of Logitech scripts does not imply misuse."
  }
}

Export-ModuleMember -Function Get-LogitechSection
