function Get-SteamLoginUsersVdfPath {
  # Common Steam install locations
  foreach ($root in @("C:\Program Files (x86)\Steam", "C:\Program Files\Steam")) {
    $vdf = Join-Path $root "config\loginusers.vdf"
    if (Test-Path $vdf) {
      return $vdf
    }
  }
  return $null
}

function Parse-SteamIdsFromVdfText {
  param([string]$Text)

  # Simple SteamID64 detection. Keeps it beginner-friendly.
  $ids = @()
  if (-not $Text) { return $ids }

  $matches = [regex]::Matches($Text, '"(7656\d{13,20})"\s*{')
  foreach ($m in $matches) { $ids += $m.Groups[1].Value }
  return ($ids | Sort-Object -Unique)
}

function Get-VacStatusPublic {
  param([string]$SteamId64)

  # Public profile HTML check (best effort).
  # Works best if the profile is public.
  $url = "https://steamcommunity.com/profiles/$SteamId64"
  $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue

  if (-not $resp -or -not $resp.Content) {
    return [ordered]@{ Checked=$false; Note="Profile not reachable or blocked." }
  }

  $c = $resp.Content
  $vac = ($c -match "VAC ban") -or ($c -match "VAC banned")
  $gameBan = ($c -match "Game ban") -or ($c -match "game ban")
  $communityBan = ($c -match "Community Ban") -or ($c -match "community ban")

  return [ordered]@{
    Checked = $true
    VacBanMarker = [bool]$vac
    GameBanMarker = [bool]$gameBan
    CommunityBanMarker = [bool]$communityBan
    Note = "Public HTML markers only; private profiles may not show reliably."
  }
}

function Get-UbisoftInstallHints {
  foreach ($p in @(
    "$env:ProgramFiles\Ubisoft\Ubisoft Game Launcher",
    "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher"
  )) {
    if (Test-Path $p) {
      return [ordered]@{
        Present = $true
        Path = $p
        LastWriteTime = (Get-Item $p).LastWriteTime
      }
    }
  }

  return [ordered]@{ Present = $false }
}

function Get-AccountsSection {
  param(
    [switch]$AllowNetworkLookups,
    [Parameter(Mandatory=$true)]$Config
  )

  # --- Steam accounts (loginusers.vdf) ---
  $steam = [ordered]@{ Found=$false; Path=$null; SteamIds=@(); VacChecks=@(); Note=$null }

  $vdfPath = Get-SteamLoginUsersVdfPath
  if ($vdfPath) {
    $steam.Found = $true
    $steam.Path = $vdfPath

    $txt = Get-Content $vdfPath -Raw -ErrorAction SilentlyContinue
    $ids = Parse-SteamIdsFromVdfText -Text $txt
    $steam.SteamIds = $ids

    if ($AllowNetworkLookups) {
      $checks = @()
      foreach ($id in ($ids | Select-Object -First 12)) {
        $checks += [ordered]@{
          SteamId64 = $id
          Vac = (Get-VacStatusPublic -SteamId64 $id)
        }
      }
      $steam.VacChecks = $checks
    } else {
      $steam.Note = "Network lookups disabled; VAC checks skipped."
    }
  }

  # --- Ubisoft presence (install hints only) ---
  $ubisoft = Get-UbisoftInstallHints

  return [ordered]@{
    Steam = $steam
    Ubisoft = $ubisoft
  }
}

Export-ModuleMember -Function Get-AccountsSection
