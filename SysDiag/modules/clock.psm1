function Show-AsciiClock {
    for ($i = 0; $i -lt 5; $i++) {
        $now = Get-Date
        Write-Host "`n $($now.ToString('HH:mm:ss'))`n"
        Start-Sleep -Seconds 1
    }
}
