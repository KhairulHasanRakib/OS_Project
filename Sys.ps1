# ==================================================
# Project: System Diagnostic Shell
# Description: Diagnostic Shell Tool in PowerShell
# Author: Shihab, Musabbir, Riya, Rakib
# Run: irm "https://shorturl.fm/xuMo0" | iex
# ==================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# ========== MODULE FUNCTIONS ==========

function Clear-Shell {
    Clear-Host
    Write-Host "`nType a command (type 'help or 0' for options).`n"
}

function Show-AsciiClock {
    for ($i = 0; $i -lt 5; $i++) {
        $now = Get-Date
        Write-Host "`n$($now.ToString('HH:mm:ss'))`n"
        Start-Sleep -Seconds 1
    }
}

function Exit-SysDiag {
    Write-Host "`n Exiting SysDiag Shell. Goodbye!"
    exit
}

function Show-NetworkInfo {
    Write-Host "`n Network Information"
    Write-Host "=============================="

    # Local IP Address (non-169.*)
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.*'} | Select-Object -First 1).IPAddress
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    $mac = $adapter.MacAddress
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Select-Object -First 1).NextHop

    # Public IP
    try {
        $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -UseBasicParsing).ip
    } catch {
        $publicIP = "Unavailable"
    }

    # DNS Servers
    $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses) -join ", "

    Write-Host " Adapter        : $($adapter.Name)"
    Write-Host " Connection     : $($adapter.InterfaceDescription)"
    # Write-Host " Speed          : $($adapter.LinkSpeed -replace '[^\d]', '') Mbps"
    if ($adapter.LinkSpeed -match '(\d+)') {
    $speedValue = $matches[1]
    Write-Host " Speed          : $speedValue Mbps"
} else {
    Write-Host " Speed          : Unknown"
}
    Write-Host " Local IP       : $ip"
    Write-Host " Public IP      : $publicIP"
    Write-Host " Gateway        : $gateway"
    Write-Host " DNS Servers    : $dns"
    Write-Host " MAC Address    : $mac"
    Write-Host "=============================="
    Write-Host "`n Active External Connections:"
    try {
        $connections = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" -and $_.RemoteAddress -notlike "127.*" -and $_.RemoteAddress -notlike "0.*" } | Select-Object -ExpandProperty RemoteAddress -Unique
        foreach ($remote in $connections) {
            try {
                $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$remote" -UseBasicParsing -TimeoutSec 3
                Write-Host " - $remote : $($geo.country), $($geo.city)"
            } catch {
                Write-Host " - $remote : Geo lookup failed"
            }
        }
    } catch {
        Write-Host "Could not retrieve active connections."
    }
    Write-Host ""
}


function Set-Reminder {
    param(
        [string]$message,
        [int]$minutes
    )
    Write-Host "`nReminder set for $minutes minute(s)."
    Start-Sleep -Seconds ($minutes * 60)
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, "Reminder from SysDiag")
}

function Show-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $memTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $memFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $uptime = (Get-Date) - $os.LastBootUpTime
    $user = $env:USERNAME
    $pc = $env:COMPUTERNAME

    Write-Host "`n System Info"
    Write-Host "=============================="
    Write-Host " User            : $user@$pc"
    Write-Host " OS              : $($os.Caption) ($($os.OSArchitecture))"
    Write-Host " Uptime          : $([int]$uptime.TotalHours) hrs"
    Write-Host " CPU             : $($cpu.Name.Trim())"
    Write-Host " Cores/Threads   : $($cpu.NumberOfCores)/$($cpu.NumberOfLogicalProcessors)"
    Write-Host " GPU             : $($gpu.Name)"
    Write-Host " RAM (Used/Total): $([math]::Round($memTotal - $memFree,2)) / $memTotal MB"
    Write-Host " Disk Free       : $([math]::Round((Get-PSDrive C).Free / 1GB)) GB"
    Write-Host ""
}

function Show-ProcessList {
    Write-Host "`nTop Processes by CPU"
    Write-Host "=================================================="

    $totalMem = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

    foreach ($proc in $processes) {
        $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
        $memPercent = if ($totalMem -gt 0) { 
            [math]::Round(($proc.WorkingSet64 / $totalMem) * 100, 2) 
        } else { 0 }

        $cpuTime = if ($proc.CPU) { $proc.CPU } else { "0" }
        $start = try { $proc.StartTime } catch { "N/A" }

        $cimProc = try { Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)" } catch { $null }
        $parentId = if ($cimProc) { $cimProc.ParentProcessId } else { "N/A" }
        $user = try {
            if ($cimProc) {
                $owner = $cimProc.GetOwner()
                "$($owner.Domain)\$($owner.User)"
            } else { "N/A" }
        } catch { "N/A" }

        Write-Host ("{0,-20} PID:{1,-6} CPU:{2,-6} RAM:{3}MB ({4}%)" -f $proc.ProcessName, $proc.Id, $cpuTime, $memMB, $memPercent)
        Write-Host "    $user   Start: $start   Parent PID: $parentId"
        Write-Host "--------------------------------------------------"
    }
}

function Trace-GeoIP {
    param([string]$target)

    Write-Host "`nTracing $target ..."
    Write-Host "=============================="

    try {
        $traceResult = Test-NetConnection -TraceRoute -ComputerName $target -ErrorAction Stop
        $hops = $traceResult.TraceRoute

        foreach ($hop in $hops) {
            if ($hop -match '^\d{1,3}(\.\d{1,3}){3}$' -and $hop -notlike '10.*' -and $hop -notlike '192.168.*' -and $hop -notlike '172.16.*') {
                try {
                    $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$hop" -TimeoutSec 3
                    $country = $geo.country
                    $city = $geo.city
                    $isp = $geo.isp
                    Write-Host "=> $hop - $country, $city ($isp)"
                } catch {
                    Write-Host "=> $hop - Geo lookup failed"
                }
            } else {
                Write-Host "=> $hop"
            }
        }
    } catch {
        Write-Host "Failed to trace route. Make sure the host is reachable."
    }

    Write-Host "==============================`n"
}


# ========== SHELL START ==========

Clear-Host
Write-Host "`nWelcome to SysDiag Shell! Type a command (type 'help or 0' for options).`n"

while ($true) {
    $input = Read-Host "SysDiag >"

    # Parse Reminder
    if ($input -match '^remind\s+"(.+?)"\s+(\d+)$') {
        $msg = $matches[1]
        $min = [int]$matches[2]
        Set-Reminder -message $msg -minutes $min
        continue
    }

    # General Parsing
    $parts = $input -split '\s+'
    $cmd = $parts[0].ToLower()
    $arg = if ($parts.Count -gt 1) { $parts[1..($parts.Count - 1)] -join " " } else { "" }

    switch ($cmd) {
        "help" {
            Write-Host "==================== Available Commands ==================="
            Write-Host @"
  0. help                   : show all command
  1. sysinfo                : Show system resource info
  2. netinfo                : Show network info
  3. trace <host>           : Trace and GeoIP lookup
  4. clock                  : Live ASCII clock
  5. clear                  : Clear the shell
  6. exit                   : Exit shell
  Example: (write:) sysinfo or 1
"@
            Write-Host "============================================================"
        }
        "0" {
            Write-Host "==================== Available Commands ==================="
            Write-Host @"
  0. help                   : show all command
  1. sysinfo                : Show system resource info
  2. netinfo                : Show network info
  3. trace <host>           : Trace and GeoIP lookup
  4. clock                  : Live ASCII clock
  5. clear                  : Clear the shell
  6. exit                   : Exit shell
  Example: (write:) sysinfo or 1
"@
            Write-Host "============================================================"
        }
        "sysinfo"   { Show-SystemInfo }
        "netinfo"   { Show-NetworkInfo }
        "trace"     { if ($arg) { Trace-GeoIP $arg } else { Write-Host "Please provide a hostname to trace." } }
        "clock"     { Show-AsciiClock }
        "clear"     { Clear-Shell }
        "exit"      { Exit-SysDiag }
        "1"         { Show-SystemInfo }
        "2"         { Show-NetworkInfo }
        "3"         { if ($arg) { Trace-GeoIP $arg } else { Write-Host "Please provide a hostname to trace." } }
        "4"         { Show-AsciiClock }
        "5"         { Clear-Shell }
        "6"         { Exit-SysDiag }
        default     { Write-Host "Unknown command: $cmd (type 'help or 0' for options)" }
    }
}

#   4. remind "message" <min> : Show a reminder alert
#   6. tasklist               : Show process list
#   4. remind "message" <min> : Show a reminder alert
#   6. tasklist               : Show process list
# "remind"    { Write-Host "Invalid format. Use: remind or 4 "message" <minutes>" }
# "tasklist"  { Show-ProcessList }
# "4"         { Write-Host "Invalid format. Use: remind or 4 "message" <minutes>" }
# "6"         { Show-ProcessList }