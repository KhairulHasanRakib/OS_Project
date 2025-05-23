function Show-NetworkInfo {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike '169.*'}).IPAddress
    if (-not $ip) { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.*'} | Select-Object -First 1).IPAddress }
    $mac = (Get-NetAdapter | Select-Object -First 1).MacAddress
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Select-Object -First 1).NextHop

    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" } | Select-Object -ExpandProperty RemoteAddress -Unique
    $geoIps = @()

    foreach ($ipAddr in $connections) {
        try {
            $geo = Invoke-RestMethod -Uri "http://ip-api.com/json/$ipAddr" -ErrorAction Stop
            $geoIps += "$ipAddr - $($geo.country)"
        } catch {
            $geoIps += "$ipAddr - Unknown"
        }
    }

    Write-Host "`n IP: $ip"
    Write-Host " MAC: $mac"
    Write-Host " Gateway: $gateway"
    Write-Host " Active IPs:"
    foreach ($g in $geoIps) {
        Write-Host " - $g"
    }
    Write-Host ""
}
