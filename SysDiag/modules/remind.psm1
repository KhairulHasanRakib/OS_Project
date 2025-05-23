function Set-Reminder {
    param(
        [string]$message,
        [int]$minutes
    )

    Write-Host "`n Reminder set for $minutes minute(s)."
    Start-Sleep -Seconds ($minutes * 60)
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, "Reminder from SysDiag")
}
