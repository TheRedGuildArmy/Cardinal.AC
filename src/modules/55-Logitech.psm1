function Get-LogitechSection {
  # This checks common Logitech locations for macro/script files.
  # It does NOT run scripts — it only lists what exists for auditing.

  $hits = @()

  # Logitech G HUB scripts folder (your original script)
  $ghubScripts = Join-Path $env:LOCALAPPDATA "LGHUB\scripts"

  # Logitech Gaming Software (older)
  $lgsPaths = @(
    Join-Path $env:APPDATA "Logitech",
    Join-Path $env:LOCALAPPDATA "Logitech"
  )

  # Helper: safely list files under a folder
  function Add-FilesFromFolder {
    param([string]$Folder, [string]$Label)

    if (-not (Test-Path $Folder)) { return }

    try {
      # Limit listing to avoid huge reports
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
        LastWriteTime = $null
        SizeBytes = $null
        Note = "Error listing folder (permissions or path issue)."
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
    Note = "This section lists Logitech-related script/config files for auditing. Presence alone is not proof of misuse."
  }
}

Export-ModuleMember -Function Get-LogitechSection
