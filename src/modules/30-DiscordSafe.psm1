function Get-DiscordSafeSection {
  # IMPORTANT:
  # This is "safe Discord scanning":
  # - It does NOT read tokens/cookies/passwords.
  # - It only checks for Discord running + install paths + mod folders.

  $running = Get-Process -Name "Discord" -ErrorAction SilentlyContinue |
    Select-Object Name, Id, Path

  $installs = @()
  foreach ($p in @("$env:LOCALAPPDATA\Discord", "$env:LOCALAPPDATA\DiscordCanary", "$env:LOCALAPPDATA\DiscordPTB")) {
    if (Test-Path $p) { $installs += $p }
  }

  $mods = @()
  if (Test-Path "$env:APPDATA\BetterDiscord") { $mods += "BetterDiscord" }
  if (Test-Path "$env:APPDATA\Vencord") { $mods += "Vencord" }

  [ordered]@{
    DiscordRunning = [bool]($running.Count -gt 0)
    RunningProcesses = $running
    InstallPaths = $installs
    ModIndicators = $mods
    Note = "This does not enumerate logged-in Discord accounts."
  }
}

Export-ModuleMember -Function Get-DiscordSafeSection
