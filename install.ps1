$ErrorActionPreference = "Stop"
$tmp = "$env:TEMP\Sekyour-Setup.exe"
Write-Host "Downloading Sekyour UI for Windows..."
Invoke-WebRequest -Uri "https://github.com/codecraf8/sekyour-dl/releases/latest/download/Sekyour-Windows.exe" -OutFile $tmp
Write-Host "Running installer..."
Start-Process -FilePath $tmp -Wait
Remove-Item $tmp
Write-Host ""
Write-Host "UI installed."
Write-Host ""
Write-Host "NOTE: Sekyour needs the secd daemon to monitor network traffic."
Write-Host "On Windows, secd requires a signed kernel driver that is not yet available."
Write-Host "The app will start but show 'Lost connection to secd' until the driver ships."
