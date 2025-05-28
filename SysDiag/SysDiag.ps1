# ===============================
# 🛠️ SysDiag Shell
# ===============================
# Author: Khairul Hasan Rakib
# Description: Diagnostic Shell Tool in PowerShell
# ===============================


# Automatically set execution policy without prompt

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force



# Load All Modules from 'Modules' Folder
$ModulesToLoad = @("sysinfo", "netinfo", "trace", "remind", "clock", "tasklist", "exit", "clear")

foreach ($module in $ModulesToLoad) {
    $path = ".\Modules\$module.psm1"
    if (Test-Path $path) {
        Import-Module $path -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning " Module $module not found!"
    }
}


Clear-Host
Write-Host "`n Welcome to SysDiag Shell! Type a command (type 'help' for options).`n"

# Start Shell
while ($true) {
    $input = Read-Host "SysDiag >"

    # Parse Reminder Special Case
    if ($input -match '^remind\s+"(.+?)"\s+(\d+)$') {
        $msg = $matches[1]
        $min = [int]$matches[2]
        Set-Reminder -message $msg -minutes $min
        continue
    }

    # General Command Parsing
    $parts = $input -split '\s+'
    $cmd = $parts[0].ToLower()
    $arg = if ($parts.Count -gt 1) { $parts[1..($parts.Count - 1)] -join " " } else { "" }

    switch ($cmd) {
        "help" {
            Write-Host "=================================================="
            Write-Host @"
Available Commands:
`n  sysinfo                : Show system resource info
  netinfo                : Show network info
  trace <host>           : Trace and GeoIP lookup
  remind "message" <min> : Show a reminder alert
  clock                  : Live ASCII clock
  tasklist               : Show process list
  clear                  : Clear the shell
  exit                   : Exit shell
"@
            Write-Host "=================================================="
        }
        "sysinfo"   { Show-SystemInfo }
        "netinfo"   { Show-NetworkInfo }
        "trace"     { if ($arg) { Trace-GeoIP $arg } else { Write-Host " Please provide a hostname to trace." } }
        "remind"    { Write-Host " Invalid format. Use: remind \"message\" <minutes>" }
        "clock"     { Show-AsciiClock }
        "tasklist"  { Show-ProcessList }
        "exit"      { Exit-SysDiag }
        "clear"     { Clear-Shell }
        default     { Write-Host " Unknown command: $cmd (type 'help' for options)" }
    }
}
