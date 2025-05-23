function Show-SystemInfo {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    $ram = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB)
    $disk = [math]::Round((Get-PSDrive C).Free / 1GB)

    Write-Host "`n CPU Usage: $cpu %"
    Write-Host " Free RAM: $ram MB"
    Write-Host " Free Disk: $disk GB`n"
}
