function Get-PciSection {
  param([Parameter(Mandatory=$true)]$Config)

  # NOTE: This is an inventory + heuristic flags.
  # It does NOT claim a device is "cheating"; it highlights unusual vendor IDs or keywords.

  $devs = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
    Where-Object { $_.PNPDeviceID -like "PCI\*" } |
    Select-Object Name, Manufacturer, PNPDeviceID

  $flags = @()
  foreach ($d in $devs) {
    $why = @()
    foreach ($v in $Config.SuspiciousPciVendors) {
      if ($d.PNPDeviceID -match "VEN_$v") { $why += "Vendor:$v" }
    }
    if ($d.Name -match "(capture|bridge|fpga|dma|pcie|adapter)") { $why += "NameHint" }

    if ($why.Count -gt 0) {
      $flags += [ordered]@{
        Name = $d.Name
        PNPDeviceID = $d.PNPDeviceID
        Why = $why
      }
    }
  }

  [ordered]@{
    Count = $devs.Count
    Devices = $devs | Select-Object -First 300
    SuspiciousHints = $flags | Select-Object -First 120
  }
}

Export-ModuleMember -Function Get-PciSection
