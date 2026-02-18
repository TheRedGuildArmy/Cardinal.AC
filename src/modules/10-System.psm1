function Get-SystemSection {
  # Basic system info for context. Keep this simple and readable.
  $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
  $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1

  $ramGB = $null
  if ($os) {
    $ramGB = [math]::Round(($os.TotalVisibleMemorySize * 1KB) / 1GB, 1)
  }

  # Windows install date (kept from original script)
  $installDate = $null
  try {
    if ($os) { $installDate = $os.InstallDate }
  } catch {}

  # Snapshot of processes (limited to avoid huge logs)
  $procs = Get-Process -ErrorAction SilentlyContinue |
    Select-Object -First 250 Name, Id, Path

  return [ordered]@{
    OS = [ordered]@{
      Caption = $os.Caption
      Version = $os.Version
      Build   = $os.BuildNumber
      Arch    = $os.OSArchitecture
      InstallDate = $installDate
    }
    CPU = $cpu.Name
    RAM_GB = $ramGB
    ProcessesSample = $procs
  }
}

Export-ModuleMember -Function Get-SystemSection
