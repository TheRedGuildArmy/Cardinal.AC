function Get-DiscordSafeSection {

  # --------------------------------------------
  # SAFE Discord Audit
  # --------------------------------------------
  # This function checks:
  #   - Whether Discord is currently running
  #   - Installed Discord locations
  #   - Known mod indicator folders/files
  #
  # It DOES NOT:
  #   - Extract tokens
  #   - Read cookies
  #   - Access browser credentials
  # --------------------------------------------

  $discordRunning = $false
  $installPaths = @()
  $modIndicators = @()

  # --------------------------------------------
  # 1️⃣ Check if Discord process is running
  # --------------------------------------------
  try {
    $process = Get-Process -Name "Discord*" -ErrorAction SilentlyContinue
    if ($process) {
      $discordRunning = $true
    }
  } catch {}

  # --------------------------------------------
  # 2️⃣ Common Discord install paths
  # --------------------------------------------
  $possiblePaths = @(
    "$env:LOCALAPPDATA\Discord",
    "$env:LOCALAPPDATA\DiscordCanary",
    "$env:LOCALAPPDATA\DiscordPTB"
  )

  foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
      $installPaths += $path
    }
  }

  # --------------------------------------------
  # 3️⃣ Known Mod Indicators
  # --------------------------------------------

  # BetterDiscord
  $betterDiscordPath = "$env:APPDATA\BetterDiscord"
  if (Test-Path $betterDiscordPath) {
    $modIndicators += "BetterDiscord"
  }

  # Vencord
  $vencordPath = "$env:APPDATA\Vencord"
  if (Test-Path $vencordPath) {
    $modIndicators += "Vencord"
  }

  # Replugged
  $repluggedPath = "$env:APPDATA\replugged"
  if (Test-Path $repluggedPath) {
    $modIndicators += "Replugged"
  }

  # Look for injected asar modifications
  foreach ($install in $installPaths) {
    try {
      $appFolders = Get-ChildItem -Path $install -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "app-*" }

      foreach ($app in $appFolders) {
        $asarPath = Join-Path $app.FullName "resources\app.asar"
        if (Test-Path $asarPath) {
          # Just presence check — not inspecting file contents
          $modIndicators += "Custom app.asar detected"
          break
        }
      }
    } catch {}
  }

  if ($modIndicators.Count -eq 0) {
    $modIndicators = @("None detected")
  }

  return [ordered]@{
    DiscordRunning = $discordRunning
    InstallPaths   = $installPaths
    ModIndicators  = $modIndicators
    Note           = "Safe audit only. No tokens, cookies, or account data are accessed."
  }
}

Export-ModuleMember -Function Get-DiscordSafeSection
