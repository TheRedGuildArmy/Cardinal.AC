function Get-SystemSection {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $ramGB = [math]::Round(($os.TotalVisibleMemorySize * 1KB) / 1GB, 1)

  # Processes (light snapshot)
  $proc = Get-Process | Select-Object -First 300 Name, Id, Path

  [ordered]@{
    OS = [ordered]@{
      Caption = $os.Caption
      Version = $os.Version
      Build   = $os.BuildNumber
      Arch    = $os.OSArchitecture
      InstallDate = $os.InstallDate
    }
    CPU = $cpu.Name
    RAM_GB = $ramGB
    ProcessesSample = $proc
  }
}

Export-ModuleMember -Function Get-SystemSection
