param(
  [string]$ProjectRef = "bzinwojowkxavfzilvat",
  [string]$EnvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) ".env")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $EnvPath -PathType Leaf)) {
  throw "Environment file not found: $EnvPath"
}

function New-RandomSecret {
  $bytes = New-Object byte[] 48
  $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {
    $generator.GetBytes($bytes)
  } finally {
    $generator.Dispose()
  }
  return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

$content = Get-Content -Raw -LiteralPath $EnvPath
$values = @{}
foreach ($line in $content -split "`r?`n") {
  if ($line -match "^(?<name>[A-Z0-9_]+)=(?<value>.*)$") {
    $values[$Matches.name] = $Matches.value.Trim()
  }
}

$supabaseKey = $values["SUPABASE_SERVICE_ROLE_KEY"]
if (-not $supabaseKey -or -not $supabaseKey.StartsWith("sb_secret_")) {
  throw "A rotated sb_secret_ key is required in SUPABASE_SERVICE_ROLE_KEY."
}

$webhookSecret = $values["REVENUECAT_WEBHOOK_AUTH"]
if (-not $webhookSecret) {
  $webhookSecret = New-RandomSecret
  $pattern = "(?m)^REVENUECAT_WEBHOOK_AUTH=.*$"
  if (-not [Regex]::IsMatch($content, $pattern)) {
    throw "REVENUECAT_WEBHOOK_AUTH is missing from the environment file."
  }
  $content = [Regex]::Replace($content, $pattern, "REVENUECAT_WEBHOOK_AUTH=$webhookSecret")

  $envDirectory = Split-Path -Parent $EnvPath
  $temporaryPath = Join-Path $envDirectory (".env.revenuecat-" + [Guid]::NewGuid().ToString("N") + ".tmp")
  try {
    [System.IO.File]::WriteAllText($temporaryPath, $content, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $EnvPath -Force
  } finally {
    if (Test-Path -LiteralPath $temporaryPath) {
      Remove-Item -LiteralPath $temporaryPath -Force
    }
  }
}

& supabase secrets set --project-ref $ProjectRef `
  "REVENUECAT_WEBHOOK_AUTH=$webhookSecret" `
  "MARKETING_SUPABASE_SECRET_KEY=$supabaseKey"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to configure RevenueCat webhook secrets in Supabase."
}

Write-Output "Configured RevenueCat webhook authentication and its dedicated Supabase server key without displaying either value."
