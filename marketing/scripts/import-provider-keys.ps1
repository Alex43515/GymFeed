param(
  [string]$KeysPath = (Join-Path ([Environment]::GetFolderPath("Desktop")) "keys.txt"),
  [string]$EnvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) ".env")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $KeysPath -PathType Leaf)) {
  throw "Keys file not found: $KeysPath"
}

if (-not (Test-Path -LiteralPath $EnvPath -PathType Leaf)) {
  throw "Environment file not found: $EnvPath. Run bootstrap-env.ps1 first."
}

$providerKeys = @{}
$legacyServiceRoleFound = $false

foreach ($line in Get-Content -LiteralPath $KeysPath) {
  $trimmed = $line.Trim()
  if (-not $trimmed -or $trimmed.StartsWith("#")) {
    continue
  }

  if ($trimmed -notmatch "^(?<name>[^=:]+?)\s*[=:]\s*(?<value>.+)$") {
    throw "Invalid keys file format. Use KEY=value, one credential per line."
  }

  $name = ($Matches.name.Trim().ToUpperInvariant() -replace "[\s-]+", "_")
  $value = $Matches.value.Trim()

  switch ($name) {
    { $_ -in @("SECRET_KEY", "OPENAI_KEY", "OPENAI_API_KEY") } {
      $providerKeys["OPENAI_API_KEY"] = $value
      break
    }
    { $_ -in @("SUPABASE_KEY", "SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY") } {
      $providerKeys["SUPABASE_SERVICE_ROLE_KEY"] = $value
      break
    }
    { $_ -in @("SERVICE_ROLE_SECRET", "SERVICE_ROLE_KEY") } {
      if ($value.StartsWith("eyJ")) {
        $legacyServiceRoleFound = $true
      } elseif ($value.StartsWith("sb_secret_")) {
        $providerKeys["SUPABASE_SERVICE_ROLE_KEY"] = $value
      } else {
        throw "The Supabase service credential must be a newly generated sb_secret_ key."
      }
      break
    }
    default {
      throw "Unrecognized credential label: $($Matches.name.Trim())"
    }
  }
}

if ($legacyServiceRoleFound) {
  throw "A legacy Supabase service-role JWT was found. Revoke it and replace it with a new sb_secret_ key before importing."
}

if (-not $providerKeys.ContainsKey("OPENAI_API_KEY") -or
    -not $providerKeys["OPENAI_API_KEY"].StartsWith("sk-")) {
  throw "OPENAI_API_KEY is missing or is not a valid OpenAI key format."
}

if (-not $providerKeys.ContainsKey("SUPABASE_SERVICE_ROLE_KEY") -or
    -not $providerKeys["SUPABASE_SERVICE_ROLE_KEY"].StartsWith("sb_secret_")) {
  throw "SUPABASE_SERVICE_ROLE_KEY is missing or is not a new sb_secret_ key."
}

$content = Get-Content -Raw -LiteralPath $EnvPath
foreach ($entry in $providerKeys.GetEnumerator()) {
  $escapedName = [Regex]::Escape($entry.Key)
  $pattern = "(?m)^$escapedName=.*$"
  if (-not [Regex]::IsMatch($content, $pattern)) {
    throw "$($entry.Key) is missing from the destination environment file."
  }
  $content = [Regex]::Replace($content, $pattern, "$($entry.Key)=$($entry.Value)")
}

$envDirectory = Split-Path -Parent $EnvPath
$temporaryPath = Join-Path $envDirectory (".env.import-" + [Guid]::NewGuid().ToString("N") + ".tmp")
try {
  [System.IO.File]::WriteAllText($temporaryPath, $content, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporaryPath -Destination $EnvPath -Force
} finally {
  if (Test-Path -LiteralPath $temporaryPath) {
    Remove-Item -LiteralPath $temporaryPath -Force
  }
}

Write-Output "Imported the rotated OpenAI and Supabase credentials into the local environment file without displaying them."
