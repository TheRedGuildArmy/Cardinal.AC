function Get-DefenderSection {
  # Uses Defender cmdlets if available. If not, we return a note.
  $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
  if (-not $mp) {
    return [ordered]@{
      Present = $false
      Note = "Windows Defender cmdlets not available (Get-MpComputerStatus missing)."
    }
  }

  return [ordered]@{
    Present = $true
    AntivirusEnabled = [bool]$mp.AntivirusEnabled
    RealTimeProtectionEnabled = [bool]$mp.RealTimeProtectionEnabled
    TamperProtection = $mp.IsTamperProtected
    AMServiceEnabled = $mp.AMServiceEnabled
    FirewallEnabled  = $mp.FirewallEnabled
    AntispywareEnabled = $mp.AntispywareEnabled
    QuickScanAgeDays = $mp.QuickScanAge
    FullScanAgeDays  = $mp.FullScanAge
  }
}

function Get-DefenderThreatSection {
  # Threat history (best-effort). If it fails, return a note.
  $threats = @()
  try {
    $raw = Get-MpThreat -ErrorAction SilentlyContinue
    if ($raw) {
      foreach ($t in ($raw | Select-Object -First 40)) {
        $threats += [ordered]@{
          ThreatName = $t.ThreatName
          SeverityID = $t.SeverityID
          ActionSuccess = $t.ActionSuccess
          InitialDetectionTime = $t.InitialDetectionTime
          RemediationTime = $t.RemediationTime
          ExecutionPath = $t.ExecutionPath
        }
      }
    }
  } catch {}

  return [ordered]@{
    Count = $threats.Count
    Items = $threats
    Note = "Threat list is best-effort and may be empty depending on permissions/system."
  }
}

function Get-SystemSecuritySection {
  # This merges a few “security posture” checks from your original script:
  # - Secure Boot
  # - Kernel DMA Protection
  # - AllowedBuses registry key inventory

  $secureBootStatus = "Unknown"
  try {
    if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
      $sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
      $secureBootStatus = if ($sb) { "Enabled" } else { "Disabled" }
    } else {
      $secureBootStatus = "Not available"
    }
  } catch {
    $secureBootStatus = "Unknown (error)"
  }

  $kernelDma = "Unknown"
  try {
    $dma = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableDmaProtection" -ErrorAction SilentlyContinue
    if ($dma -and $dma.EnableDmaProtection -eq 1) { $kernelDma = "Enabled" }
    else { $kernelDma = "Disabled or not supported" }
  } catch {
    $kernelDma = "Unknown (error)"
  }

  # AllowedBuses key inventory
  $allowedBusesPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses"
  $allowedBuses = @()
  $allowedBusesNote = $null

  if (Test-Path $allowedBusesPath) {
    try {
      $subs = Get-ChildItem -Path $allowedBusesPath -ErrorAction Stop
      foreach ($s in $subs) { $allowedBuses += $s.PSChildName }
      if ($allowedBuses.Count -eq 0) { $allowedBusesNote = "No subkeys found (only default key exists)." }
    } catch {
      $allowedBusesNote = "Access error reading AllowedBuses."
    }
  } else {
    $allowedBusesNote = "AllowedBuses key not found."
  }

  return [ordered]@{
    SecureBoot = $secureBootStatus
    KernelDmaProtection = $kernelDma
    AllowedBuses = $allowedBuses
    AllowedBusesNote = $allowedBusesNote
  }
}

Export-ModuleMember -Function Get-DefenderSection, Get-DefenderThreatSection, Get-SystemSecuritySection
