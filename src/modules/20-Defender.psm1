function Get-DefenderSection {
  # NOTE: Get-MpComputerStatus is available when Defender is present.
  $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
  if (-not $mp) {
    return [ordered]@{
      Present = $false
      Note = "Windows Defender cmdlets not available."
    }
  }

  [ordered]@{
    Present = $true
    AntivirusEnabled = [bool]$mp.AntivirusEnabled
    RealTimeProtectionEnabled = [bool]$mp.RealTimeProtectionEnabled
    TamperProtection = $mp.IsTamperProtected
    AMServiceEnabled = $mp.AMServiceEnabled
  }
}

Export-ModuleMember -Function Get-DefenderSection
