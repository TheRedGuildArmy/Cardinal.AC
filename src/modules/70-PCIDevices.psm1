function Get-PciSection {
  param([Parameter(Mandatory=$true)]$Config)

  # Inventory PCI devices and add heuristic flags. This is NOT proof of cheating.
  $devs = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
    Where-Object { $_.PNPDeviceID -like "PCI\*" } |
    Select-Object Name, Manufacturer, PNPDeviceID

  $flags = @()

  foreach ($d in $devs) {
    $why = @()

    foreach ($v in $Config.SuspiciousPciVendors) {
      if ($v -and ($d.PNPDeviceID -match ("VEN_" + [regex]::Escape($v)))) {
        $why += ("Vendor:" + $v)
      }
    }

    # Generic name hints (kept broad)
    if ($d.Name -match "(capture|bridge|fpga|adapter|pcie)") { $why += "NameHint" }

    if ($why.Count -gt 0) {
      $flags += [ordered]@{
        Name = $d.Name
        PNPDeviceID = $d.PNPDeviceID
        Why = $why
      }
    }
  }

  return [ordered]@{
    Count = $devs.Count
    Devices = ($devs | Select-Object -First 350)
    SuspiciousHints = ($flags | Select-Object -First 150)
    Note = "SuspiciousHints are heuristics only; review manually."
  }
}

Export-ModuleMember -Function Get-PciSection
