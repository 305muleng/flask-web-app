$ErrorActionPreference = 'Stop'
$deployRoot = 'D:\code\test\deployment\flask-web-app'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$pythonBinary = Join-Path $workspaceRoot '.venv\Scripts\python.exe'
$pidFile = Join-Path $deployRoot 'app.pid'
$runnerFile = Join-Path $deployRoot 'serve.py'
New-Item -ItemType Directory -Path $deployRoot -Force | Out-Null

if (Test-Path -LiteralPath $pidFile) {
    $previousPid = [int](Get-Content -LiteralPath $pidFile -Raw).Trim()
    $previousProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $previousPid"
    if ($previousProcess) {
        if ($previousProcess.CommandLine -notlike "*$runnerFile*") {
            throw 'Recorded process does not belong to this experiment; refusing to stop it.'
        }
        Stop-Process -Id $previousPid -Force
        Wait-Process -Id $previousPid -Timeout 10 -ErrorAction SilentlyContinue
    }
}

$listener = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue
if ($listener) { throw 'Port 5000 is occupied. No unrelated process has been stopped.' }

Copy-Item -LiteralPath (Join-Path $workspaceRoot 'app.py') -Destination $deployRoot -Force
@'
from app import app

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False, use_reloader=False)
'@ | Set-Content -LiteralPath $runnerFile -Encoding UTF8

$serverProcess = Start-Process -FilePath $pythonBinary -ArgumentList @('"' + $runnerFile + '"') -WorkingDirectory $deployRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $deployRoot 'stdout.log') -RedirectStandardError (Join-Path $deployRoot 'stderr.log') -PassThru
$serverProcess.Id | Set-Content -LiteralPath $pidFile -Encoding ASCII

for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Seconds 1
    if ($serverProcess.HasExited) {
        Get-Content -LiteralPath (Join-Path $deployRoot 'stderr.log')
        throw 'Flask process exited before the health check succeeded.'
    }
    try {
        $health = Invoke-WebRequest -Uri 'http://127.0.0.1:5000/' -UseBasicParsing -TimeoutSec 3
        if ($health.StatusCode -eq 200 -and $health.Content.Trim() -eq 'Hello, CI/CD with Jenkins!') {
            Write-Output 'Deployment healthy: http://localhost:5000/'
            exit 0
        }
    } catch {
        if ($attempt -eq 19) { throw }
    }
}
throw 'Application did not return the expected content.'
