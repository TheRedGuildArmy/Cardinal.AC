@{
  # =========================
  # Cardinal.AC Configuration
  # =========================

  # If true, allows public web checks (VAC checks use public Steam profile pages).
  EnableNetworkLookups = $true

  # Folders to scan (kept reasonable; avoids full-disk crawling)
  ScanTargets = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:APPDATA",
    "$env:LOCALAPPDATA",
    "C:\ProgramData"
  )

  # Add extra paths if you want (example: game folder, custom tools folder)
  ExtraScanTargets = @()

  # File extensions to flag (heuristics)
  SuspiciousExtensions = @(
    ".exe",".dll",".sys",
    ".ahk",".lua",".py",".ps1",".bat",".cmd",".vbs",
    ".zip",".rar",".7z"
  )

  # Keyword-based heuristics (names only; not bypass-proof, just useful)
  SuspiciousKeywords = @(
    "cheat","loader","inject","hook","bypass","spoof","unlock",
    "aimbot","esp","trigger","silent",
    "macro","autohotkey",
    "dma","kmbox","arduino","mapper","driver"
  )

  # Optional: exact filenames you want to always flag if found
  WatchFileNames = @(
    "pcileech",
    "kmbox",
    "dma",
    "mapper"
  )

  # Prefetch settings
  PrefetchMaxFiles = 400

  # PCIe suspicious hints: Vendor IDs to highlight (heuristic only)
  SuspiciousPciVendors = @(
    "1CD7", # example seen in capture/bridge devices
    "1A86"  # QinHeng Electronics (USB-serial bridges like CH340)
  )
}
