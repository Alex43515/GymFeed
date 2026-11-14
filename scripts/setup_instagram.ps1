# Run once locally. The key is stored in your Windows user environment, not Git.
$ErrorActionPreference = 'Stop'
$instagramSecureToken = Read-Host 'Paste your Apify API token (input is hidden)' -AsSecureString
$instagramPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($instagramSecureToken)
try {
    $instagramToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($instagramPointer).Trim()
    if ([string]::IsNullOrWhiteSpace($instagramToken)) { throw 'No token entered.' }
    [Environment]::SetEnvironmentVariable('APIFY_TOKEN', $instagramToken, 'User')
    Write-Host 'Key saved for your Windows user. You can now run download_instagram.py with a profile URL.'
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($instagramPointer)
    $instagramToken = $null
    $instagramSecureToken.Dispose()
}
