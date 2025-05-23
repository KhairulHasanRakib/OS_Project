function Show-ProcessList {
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
    Format-Table -Property Name, Id, CPU, WS -AutoSize
}

