# =========================
# 00-Utils.psm1
# Shared helpers used across the scanner
# =========================

function Show-CardinalBanner {
    <#
      Prints the Cardinal.AC title in "special text" (ASCII block style).
      Keep this in one function so it’s easy to change later.
    #>

    $banner = @'
█▀▀ ▄▀█ █▀█ █▀▄ █ █▄░█ ▄▀█ █░░ ░ ▄▀█ █▀▀
█▄▄ █▀█ █▀▄ █▄▀ █ █░▀█ █▀█ █▄▄ ▄ █▀█ █▄▄
'@

    Write-Host ""
    Write-Host $banner
}

function Convert-ToMonoAdvisoryFont {
    <#
      Converts normal A-Z / a-z to the Unicode monospace-ish characters you pasted.
      This is ONLY for display; it doesn’t change what the script does.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    # Mapping tables for A-Z and a-z
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

    $out = New-Object System.Text.StringBuilder

    foreach ($ch in $Text.ToCharArray()) {
        if ($mapUpper.ContainsKey($ch)) {
            [void]$out.Append($mapUpper[$ch])
        } elseif ($mapLower.ContainsKey($ch)) {
            [void]$out.Append($mapLower[$ch])
        } else {
            # Keep spaces, punctuation, numbers as-is
            [void]$out.Append($ch)
        }
    }

    return $out.ToString()
}

function Show-ConsentGate {
    <#
      Shows a generalized advisory and requires Y/N confirmation before continuing.

      Notes:
      - Keep this “high level” so you’re not revealing exact indicator logic.
      - Still be honest: it scans local system artifacts, creates a report, and may do public ban lookups.
    #>

    param(
        [string]$ProductName = "Cardinal.AC",
        [string]$OutputDirHint = "output\",
        [switch]$AllowNetworkLookups
    )

    Show-CardinalBanner

    # High-level advisory (don’t list exact folders/keywords, but do disclose broad categories)
    $advisoryPlain = @"
$ProductName will perform a local system audit to identify potentially unauthorized tools and suspicious activity indicators.
This may include reviewing running processes, services/drivers, startup locations, scheduled tasks, prefetch execution traces,
and selected files in common user directories. A report will be created in: $OutputDirHint

If enabled, the scan may also perform public reputation checks (e.g., VAC status) using publicly accessible profile pages.
No passwords are collected. No browser cookies or authentication tokens are extracted.

Continue?
"@

    if ($AllowNetworkLookups) {
        # Keep this subtle – still generalized.
        $advisoryPlain += "`nNetwork lookups: ENABLED (public profile checks only)."
    } else {
        $advisoryPlain += "`nNetwork lookups: DISABLED."
    }

    $advisoryFancy = Convert-ToMonoAdvisoryFont -Text $advisoryPlain

    Write-Host $advisoryFancy
    Write-Host ""

    while ($true) {
        $ans = Read-Host "Type Y to continue or N to exit"
        if (-not $ans) { continue }

        switch ($ans.Trim().ToLower()) {
            "y" { return $true }
            "n" { return $false }
            default { Write-Host "Please type Y or N." }
        }
    }
}

Export-ModuleMember -Function Show-CardinalBanner, Convert-ToMonoAdvisoryFont, Show-ConsentGate
