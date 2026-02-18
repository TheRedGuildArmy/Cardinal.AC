@{
  # =========================
  # Cardinal.AC Configuration
  # =========================

  EnableNetworkLookups = $true

  ScanTargets = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:APPDATA",
    "$env:LOCALAPPDATA",
    "C:\ProgramData"
  )

  ExtraScanTargets = @()

  SuspiciousExtensions = @(
    ".exe",".dll",".sys",
    ".ahk",".lua",".py",".ps1",".bat",".cmd",".vbs",
    ".zip",".rar",".7z"
  )

  SuspiciousKeywords = @(
    "cheat","loader","inject","hook","bypass","spoof","unlock",
    "aimbot","esp","trigger","silent",
    "macro","autohotkey",
    "dma","kmbox","arduino","mapper","driver"
  )

  WatchFileNames = @(
    "Dapper.dll"
  )

  PrefetchMaxFiles = 400

  SuspiciousPciVendors = @(
    "1CD7",
    "1A86"
  )
}
