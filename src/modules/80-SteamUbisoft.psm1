function Get-SteamAccountsFromVdf {
  # Reads Steam loginusers.vdf (local list of accounts used on this PC)
  $steamPaths = @(
    "C:\Program Files (x86)\Steam",
    "C:\Program Files\Steam"
  )

  foreach ($root in $steamPaths) {
    $vdf = Join-Path $root "config\loginusers.vdf"
    if (Test-Path $vdf) { return [ordered]@{ Found=$true; Path=$vdf; Content=(Get-Content $vdf -Raw) } }
  }

  return [ordered]@{ Found=$false }
}

function Parse-SteamIdsFromVdfText {
  param([string]$Text)

  # Very simple parse: SteamID64 lines look like: "7656...."
  # This keeps it easy for beginners and avoids a full VDF parser.
  $ids = @()
  if (-not $Text) { return $ids }

  $matches = [regex]::Matches($Text, '"(7656\d{13,20})"\s*{')
  foreach ($m in $matches) {
    $ids += $m.Groups[1].Value
  }
  return ($ids | Sort-Object -Unique)
}

function Get-VacStatusPublic {
  param([string]$SteamId64)

  # Public check: fetch profile page HTML and look for VAC ban markers.
  # NOTE: This only works reliably for public profiles.
  $url = "https://steamcommunity.com/profiles/$SteamId64"
  $html = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue

  if (-not $html -or -not $html.Content) {
    return [ordered]@{ Checked=$false; Note="Profile not reachable or request blocked." }
  }

  $c = $html.Content
  $isVac = ($c -match "VAC ban") -or ($c -match "VAC banned")
  $gameBan = ($c -match "Game ban") -or ($c -match "game ban")

  [ordered]@{
    Checked = $true
    VacBanMarker = [bool]$isVac
    GameBanMarker = [bool]$gameBan
    Note = "This is a best-effort public HTML check (public profiles only)."
  }
}

function Get-UbisoftInstallHints {
  $paths = @(
    "$env:ProgramFiles\Ubisoft\Ubisoft Game Launcher",
    "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher"
  )
  foreach ($p in $paths) {
    if (Test-Path $p) {
      return [ordered]@{ Present=$true; Path=$p; LastWriteTime=(Get-Item $p).LastWriteTime }
    }
  }
  return [ordered]@{ Present=$false }
}

function Get-AccountsSection {
  param([switch]$AllowNetworkLookups)

  # --- Steam accounts on this PC ---
  $vdf = Get-SteamAccountsFromVdf
  $steam = [ordered]@{ Found=$false; SteamIds=@(); VacChecks=@() }

  if ($vdf.Found) {
    $steam.Found = $true
    $steam.Path = $vdf.Path
    $ids = Parse-SteamIdsFromVdfText -Text $vdf.Content
    $steam.SteamIds = $ids

    if ($AllowNetworkLookups) {
      $checks = @()
      foreach ($id in ($ids | Select-Object -First 10)) {
        $checks += [ordered]@{
          SteamId64 = $id
          Vac = Get-VacStatusPublic -SteamId64 $id
        }
      }
      $steam.VacChecks = $checks
    } else {
      $steam.Note = "Network lookups disabled; VAC checks skipped."
    }
  }

  # --- Ubisoft hints (install presence only) ---
  $ubi = Get-UbisoftInstallHints

  [ordered]@{
    Steam = $steam
    Ubisoft = $ubi
  }
}

Export-ModuleMember -Function Get-AccountsSection
