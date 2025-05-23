function Trace-GeoIP {
    param([string]$host)

    Write-Host "`nTracing $host ...`n"
    $hops = Test-NetConnection -TraceRoute -ComputerName $host | Select-Object -ExpandProperty TraceRoute

    foreach ($hop in $hops) {
        try {
            $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$hop" -ErrorAction Stop
            Write-Host " $hop - $($geo.country), $($geo.city)"
        } catch {
            Write-Host " $hop - Unknown"
        }
    }
    Write-Host ""
}
