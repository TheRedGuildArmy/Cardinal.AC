function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-CardinalBanner {
$banner = @'
█▀▀ ▄▀█ █▀█ █▀▄ █ █▄░█ ▄▀█ █░░ ░ ▄▀█ █▀▀
█▄▄ █▀█ █▀▄ █▄▀ █ █░▀█ █▀█ █▄▄ ▄ █▀█ █▄▄
'@
  Write-Host ""
  Write-Host $banner -ForegroundColor DarkRed
}

function Convert-ToMonoAdvisoryFont {
  param([Parameter(Mandatory=$true)][string]$Text)

  $mapUpper = @{
    'A'='𝙰'; 'B'='𝙱'; 'C'='𝙲'; 'D'='𝙳'; 'E'='𝙴'; 'F'='𝙵'; 'G'='𝙶'; 'H'='𝙷'; 'I'='𝙸'; 'J'='𝙹';
    'K'='𝙺'; 'L'='𝙻'; 'M'='𝙼'; 'N'='𝙽'; 'O'='𝙾'; 'P'='𝙿'; 'Q'='𝚀'; 'R'='𝚁'; 'S'='𝚂'; 'T'='𝚃';
    'U'='𝚄'; 'V'='𝚅'; 'W'='𝚆'; 'X'='𝚇'; 'Y'='𝚈'; 'Z'='𝚉';
  }
  $mapLower = @{
    'a'='𝚊'; 'b'='𝚋'; 'c'='𝚌'; 'd'='𝚍'; 'e'='𝚎'; 'f'='𝚏'; 'g'='𝚐'; 'h'='𝚑'; 'i'='𝚒'; 'j'='𝚓';
    'k'='𝚔'; 'l'='𝚕'; 'm'='𝚖'; 'n'='𝚗'; 'o'='𝚘'; 'p'='𝚙'; 'q'='𝚚'; 'r'='𝚛'; 's'='𝚜'; 't'='𝚝';
    'u'='𝚞'; 'v'='𝚟'; 'w'='𝚠'; 'x'='𝚡'; 'y'='𝚢'; 'z'='𝚣';
  }

  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $Text.ToCharArray()) {
    if ($mapUpper.ContainsKey($ch)) { [void]$sb.Append($mapUpper[$ch]) }
    elseif ($mapLower.ContainsKey($ch)) { [void]$sb.Append($mapLower[$ch]) }
    else { [void]$sb.Append($ch) }
  }
  return $sb.ToString()
}

function Show-ConsentGate {
  param(
    [string]$ProductName = "Cardinal.AC",
    [string]$OutputDirHint = ".\output\",
    [switch]$AllowNetworkLookups
  )

  Clear-Host
  Show-CardinalBanner
  Start-Sleep -Milliseconds 150

  $plain = @"
$ProductName will perform a local system audit and generate a report.

- Scans Cheats, Scripts, and possibly DMA Files
- Gives a config section to search for specific files/names
- Checks Discord activity during the scan (running process + install/mod indicators)
- Scans the PC for Ubisoft / Steam presence and can check VAC status (public info)
- Scans Prefetch execution traces (admin recommended)
- Checks Windows Defender Antivirus status
- Collects Monitors & EDID Information
- Collects suspicious PCIe device hints (heuristics)
- Produces an organized final .txt report
- Code is commented and organized to be easy to edit

No passwords are collected. No browser cookies or authentication tokens are extracted.
Report output folder: $OutputDirHint

Continue?
"@

  if ($AllowNetworkLookups) { $plain += "`nNetwork lookups: ENABLED (public profile checks only)." }
  else { $plain += "`nNetwork lookups: DISABLED." }

  Write-Host (Convert-ToMonoAdvisoryFont -Text $plain)
  Write-Host ""

  while ($true) {
    $ans = Read-Host "Type Y to continue or N to exit"
    if (-not $ans) { continue }
    switch ($ans.Trim().ToLower()) {
      "y" { return $true }
      "n" { return $false }
      default { Write-Host "Please type Y or N." -ForegroundColor Yellow }
    }
  }
}

Export-ModuleMember -Function Test-IsAdmin, Show-CardinalBanner, Convert-ToMonoAdvisoryFont, Show-ConsentGate
