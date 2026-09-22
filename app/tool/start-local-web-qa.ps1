[CmdletBinding()]
param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 64580,

  [ValidateRange(30, 600)]
  [int]$StartupTimeoutSeconds = 180,

  [switch]$OpenBrowser,

  [switch]$Stop
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $appRoot 'config\dev.json'
$buildPath = Join-Path $appRoot 'build\web'
$dartToolPath = Join-Path $appRoot '.dart_tool'
$statePath = Join-Path $dartToolPath 'musemend-local-web-qa.json'
$serverScript = Join-Path $PSScriptRoot 'serve-local-web-qa.ps1'
$stdoutPath = Join-Path $dartToolPath 'musemend-local-web-qa.stdout.log'
$stderrPath = Join-Path $dartToolPath 'musemend-local-web-qa.stderr.log'
$script:StoppedManagedServerPid = $null

function Stop-ManagedLocalWebQa {
  if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    return $false
  }

  try {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $processId = [int]$state.processId
    $serverProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -ne $serverProcess) {
      if (-not $state.processStartedAtUnixMs) {
        throw "The managed local QA state is missing process metadata. Refusing to stop PID $processId. Remove $statePath only after verifying the process manually."
      }

      $recordedStartTimeMs = [int64]$state.processStartedAtUnixMs
      $actualStartTimeMs = ([DateTimeOffset]$serverProcess.StartTime.ToUniversalTime()).ToUnixTimeMilliseconds()
      if ([math]::Abs($actualStartTimeMs - $recordedStartTimeMs) -gt 1000) {
        throw "PID $processId no longer matches the local QA process recorded by this runbook. Refusing to stop a potentially reused PID."
      }

      # Only stop the process tree identified in our own state file.
      $taskkillOutput = & taskkill.exe /PID $processId /T /F 2>&1
      if ($LASTEXITCODE -ne 0 -and (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
        throw "Could not stop managed local QA server (PID $processId): $taskkillOutput"
      }
      $deadline = (Get-Date).AddSeconds(10)
      while ((Get-Process -Id $processId -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 200
      }
      if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
        throw "Managed local QA server (PID $processId) did not exit within 10 seconds."
      }
      $script:StoppedManagedServerPid = $processId
    }
  } finally {
    Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue
  }

  return $true
}

function Assert-PortAvailable {
  param([int]$RequestedPort)

  # Get-NetTCPConnection can hide listeners when this command is not elevated.
  # A TCP connection check is reliable for the local port and is enough to avoid
  # overwriting an untracked server.
  $client = [System.Net.Sockets.TcpClient]::new()
  try {
    $connect = $client.BeginConnect('127.0.0.1', $RequestedPort, $null, $null)
    if (-not $connect.AsyncWaitHandle.WaitOne(500)) {
      return
    }
    $client.EndConnect($connect)
  } catch [System.Net.Sockets.SocketException] {
    return
  } finally {
    $client.Dispose()
  }

  throw "Port $RequestedPort already accepts a local connection. It was not started by this runbook, so it was left untouched. Stop its owner explicitly, then run this command again."
}

function Repair-StaleFlutterLauncherLock {
  $flutterCommand = Get-Command flutter -ErrorAction Stop
  $flutterBin = Split-Path -Parent $flutterCommand.Source
  $cachePath = Join-Path $flutterBin 'cache'
  $requiredLock = Join-Path $cachePath 'lockfile'
  $launcherLock = Join-Path $cachePath 'flutter.bat.lock'

  if (-not (Test-Path -LiteralPath $requiredLock -PathType Leaf)) {
    New-Item -ItemType File -Path $requiredLock -Force | Out-Null
  }

  if (Test-Path -LiteralPath $launcherLock -PathType Leaf) {
    $activeFlutterTools = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
      $_.ProcessName -in @('dart', 'flutter')
    })
    if ($activeFlutterTools.Count -eq 0) {
      Remove-Item -LiteralPath $launcherLock -Force
      Write-Output 'Removed stale Flutter launcher lock.'
    }
  }
}

if ($Stop) {
  $stopped = Stop-ManagedLocalWebQa
  if ($stopped) {
    Write-Output "Stopped previous MuseMend local QA server (PID $script:StoppedManagedServerPid)."
  } else {
    Write-Output 'No managed MuseMend local QA server is running.'
  }
  exit 0
}

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
  throw "Missing $configPath. Copy config\\dev.example.json to config\\dev.json and set only Development Supabase URL plus publishable key."
}

if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
  throw "Missing local QA server script: $serverScript"
}

New-Item -ItemType Directory -Path $dartToolPath -Force | Out-Null
Stop-ManagedLocalWebQa | Out-Null
Assert-PortAvailable -RequestedPort $Port
Repair-StaleFlutterLauncherLock

Push-Location $appRoot
try {
  # Disabling PWA prevents a service worker from surviving between QA runs.
  & flutter build web --release --pwa-strategy=none --dart-define-from-file=config/dev.json
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Web build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
$powerShellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
$serverArguments = '-NoLogo -NoProfile -File "{0}" -Port {1} -SiteRoot "{2}" -StatePath "{3}"' -f $serverScript, $Port, $buildPath, $statePath
$serverStartParameters = @{
  FilePath = $powerShellPath
  ArgumentList = $serverArguments
  WorkingDirectory = $appRoot
  WindowStyle = 'Hidden'
  RedirectStandardOutput = $stdoutPath
  RedirectStandardError = $stderrPath
  PassThru = $true
}
Start-Process @serverStartParameters | Out-Null

$deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
$ready = $false
while ((Get-Date) -lt $deadline) {
  if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    $errorText = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
    Start-Sleep -Milliseconds 100
    continue
  }

  try {
    $response = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$Port/"
    if ($response.StatusCode -eq 200) {
      $ready = $true
      break
    }
  } catch {
    # HttpListener may need a moment to bind after the release build completes.
  }
  Start-Sleep -Milliseconds 250
}

if (-not $ready) {
  Stop-ManagedLocalWebQa | Out-Null
  throw "MuseMend local QA server did not become ready within $StartupTimeoutSeconds seconds."
}

$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$url = "http://127.0.0.1:$Port/?qa=$runId#/sign-in"
Write-Output "MuseMend local QA is ready: $url"
Write-Output "Stop it later with: .\\tool\\start-local-web-qa.ps1 -Stop"

if ($OpenBrowser) {
  Start-Process $url
}
