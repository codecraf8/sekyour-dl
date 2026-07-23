$ErrorActionPreference = "Stop"
$tmp = "$env:TEMP\Sekyour-Setup.exe"
Write-Host "Downloading Sekyour for Windows..."
Invoke-WebRequest -Uri "https://github.com/codecraf8/sekyour-dl/releases/latest/download/Sekyour-Windows.exe" -OutFile $tmp
Write-Host "Running installer..."
Start-Process -FilePath $tmp -Wait
Remove-Item $tmp
Write-Host "Done."
