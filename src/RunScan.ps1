Import-Module "$PSScriptRoot\modules\00-Utils.psm1" -Force

# If your scanner supports network lookups (VAC checks), you can wire it to a config flag:
$allowNetwork = $true  # or from config: $Config.EnableNetworkLookups

$ok = Show-ConsentGate -ProductName "Cardinal.AC" -OutputDirHint ".\output\" -AllowNetworkLookups:([bool]$allowNetwork)
if (-not $ok) {
    Write-Host "Scan cancelled by user."
    exit 0
}
