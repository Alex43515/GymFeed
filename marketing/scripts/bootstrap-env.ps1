param(
  [string]$SupabaseUrl = "https://bzinwojowkxavfzilvat.supabase.co"
)

$ErrorActionPreference = "Stop"
$marketingDir = Split-Path -Parent $PSScriptRoot
$examplePath = Join-Path $marketingDir ".env.example"
$envPath = Join-Path $marketingDir ".env"

if (Test-Path -LiteralPath $envPath) {
  throw "$envPath already exists. Refusing to overwrite local credentials."
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

$values = @{
  "MARKETING_INTERNAL_TOKEN" = New-RandomSecret
  "MARKETING_APPROVAL_TOKEN" = New-RandomSecret
  "N8N_DOMAIN" = "localhost"
  "N8N_PROTOCOL" = "http"
  "N8N_PUBLIC_URL" = "http://localhost:5678"
  "N8N_SECURE_COOKIE" = "false"
  "POSTGRES_PASSWORD" = New-RandomSecret
  "N8N_ENCRYPTION_KEY" = New-RandomSecret
  "SUPABASE_URL" = $SupabaseUrl
  "SUPABASE_SERVICE_ROLE_KEY" = ""
  "REVENUECAT_WEBHOOK_AUTH" = New-RandomSecret
  "OPENAI_API_KEY" = ""
  "GEMINI_API_KEY" = ""
  "BYTEPLUS_API_KEY" = ""
  "BLOTATO_API_KEY" = ""
}

$content = Get-Content -Raw -LiteralPath $examplePath
foreach ($entry in $values.GetEnumerator()) {
  $escapedName = [Regex]::Escape($entry.Key)
  $replacement = "$($entry.Key)=$($entry.Value)"
  $content = [Regex]::Replace($content, "(?m)^$escapedName=.*$", $replacement)
}

[System.IO.File]::WriteAllText($envPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Output "Created $envPath with generated local infrastructure secrets. Provider keys remain blank."
