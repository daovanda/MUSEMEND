[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateRange(1024, 65535)]
  [int]$Port,

  [Parameter(Mandatory = $true)]
  [string]$SiteRoot,

  [Parameter(Mandatory = $true)]
  [string]$StatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedRoot = [System.IO.Path]::GetFullPath($SiteRoot).TrimEnd([char[]]@('\', '/'))
if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
  throw "Static Web directory does not exist: $resolvedRoot"
}

$mimeTypes = @{
  '.css' = 'text/css; charset=utf-8'
  '.dart' = 'application/javascript; charset=utf-8'
  '.html' = 'text/html; charset=utf-8'
  '.ico' = 'image/x-icon'
  '.js' = 'application/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.map' = 'application/json; charset=utf-8'
  '.png' = 'image/png'
  '.svg' = 'image/svg+xml'
  '.wasm' = 'application/wasm'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.webp' = 'image/webp'
}

function Get-SafeFilePath {
  param([string]$RequestPath)

  $relativePath = [Uri]::UnescapeDataString($RequestPath.TrimStart('/'))
  if ([string]::IsNullOrWhiteSpace($relativePath)) {
    return (Join-Path $resolvedRoot 'index.html')
  }

  if ($relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
    return $null
  }

  $candidate = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot $relativePath))
  $rootPrefix = "$resolvedRoot$([System.IO.Path]::DirectorySeparatorChar)"
  if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  if (Test-Path -LiteralPath $candidate -PathType Leaf) {
    return $candidate
  }

  # Flutter routes are client-side; non-file paths deliberately receive index.html.
  return (Join-Path $resolvedRoot 'index.html')
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

try {
  $listener.Start()
  $processStartedAt = (Get-Process -Id $PID -ErrorAction Stop).StartTime.ToUniversalTime()
  $state = [ordered]@{
    processId = $PID
    port = $Port
    startedAt = (Get-Date).ToString('o')
    processStartedAtUnixMs = ([DateTimeOffset]$processStartedAt).ToUnixTimeMilliseconds()
  } | ConvertTo-Json
  Set-Content -LiteralPath $StatePath -Value $state -Encoding utf8
  Write-Output "MuseMend local QA server listening on http://127.0.0.1:$Port/"

  while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
      $filePath = Get-SafeFilePath -RequestPath $context.Request.Url.AbsolutePath
      if ($null -eq $filePath) {
        $context.Response.StatusCode = [int][System.Net.HttpStatusCode]::BadRequest
        $context.Response.Close()
        continue
      }

      $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
      $contentType = $mimeTypes[$extension]
      if ([string]::IsNullOrWhiteSpace($contentType)) {
        $contentType = 'application/octet-stream'
      }

      $content = [System.IO.File]::ReadAllBytes($filePath)
      $context.Response.StatusCode = [int][System.Net.HttpStatusCode]::OK
      $context.Response.ContentType = $contentType
      $context.Response.ContentLength64 = $content.Length
      # Local QA must never reuse an old Flutter bundle or service-worker response.
      $context.Response.Headers['Cache-Control'] = 'no-store, max-age=0, must-revalidate'
      $context.Response.Headers['Pragma'] = 'no-cache'
      $context.Response.Headers['Expires'] = '0'
      $context.Response.OutputStream.Write($content, 0, $content.Length)
      $context.Response.Close()
    } catch {
      try {
        $context.Response.StatusCode = [int][System.Net.HttpStatusCode]::InternalServerError
        $context.Response.Close()
      } catch {
        # The caller may have disconnected; the listener remains available.
      }
      Write-Error $_
    }
  }
} finally {
  if ($listener.IsListening) {
    $listener.Stop()
  }
  $listener.Close()
  if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
    try {
      $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
      if ([int]$state.processId -eq $PID) {
        Remove-Item -LiteralPath $StatePath -Force -ErrorAction SilentlyContinue
      }
    } catch {
      # Shutdown must not leave the listener open because state cleanup failed.
    }
  }
}
