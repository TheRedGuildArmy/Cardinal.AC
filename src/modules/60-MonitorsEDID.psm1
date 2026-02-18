function Get-MonitorEdidSection {
  # WmiMonitorID gives friendly fields derived from EDID.
  $mon = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue

  if (-not $mon) {
    return [ordered]@{
      Count = 0
      Items = @()
      Note = "WmiMonitorID not available or blocked."
    }
  }

  $items = foreach ($m in $mon) {
    $man = ([char[]]$m.ManufacturerName | Where-Object { $_ -ne 0 }) -join ""
    $name = ([char[]]$m.UserFriendlyName | Where-Object { $_ -ne 0 }) -join ""
    $serial = ([char[]]$m.SerialNumberID | Where-Object { $_ -ne 0 }) -join ""

    [ordered]@{
      Manufacturer = $man
      Name = $name
      Serial = $serial
      Year = $m.YearOfManufacture
      Week = $m.WeekOfManufacture
      InstanceName = $m.InstanceName
    }
  }

  return [ordered]@{
    Count = $items.Count
    Items = $items
  }
}

Export-ModuleMember -Function Get-MonitorEdidSection
