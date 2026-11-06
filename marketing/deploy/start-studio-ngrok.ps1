[CmdletBinding()]
param(
    [string[]]$OwnerEmail
)

$ErrorActionPreference = 'Stop'
$accessFile = Join-Path $env:LOCALAPPDATA 'GymFeedStudio/tunnel-access.txt'
if (!$OwnerEmail -and (Test-Path -LiteralPath $accessFile)) {
    $OwnerEmail = @(Get-Content -LiteralPath $accessFile | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
if (!$OwnerEmail -or @($OwnerEmail -notmatch '^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').Count -gt 0) {
    throw 'Configure valid Google email addresses with -OwnerEmail or in the local tunnel-access.txt file.'
}
$owners = ($OwnerEmail | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique | ForEach-Object { "'$_'" }) -join ', '
$studio = 'http://127.0.0.1:3100'
Invoke-WebRequest -Uri $studio -UseBasicParsing -TimeoutSec 5 | Out-Null

$invalidOrigin = "'origin' in req.headers ? req.headers['origin'] != ['https://' + req.url.host] : !(req.method in ['GET', 'HEAD'])"
$deny = @{ type = 'deny'; config = @{ status_code = 403 } }
$policy = @{
    on_http_request = @(
        @{ expressions = @($invalidOrigin); actions = @($deny) }
        @{ actions = @(@{ type = 'oauth'; config = @{ provider = 'google' } }) }
        @{ expressions = @("!(actions.ngrok.oauth.identity.email in [$owners])"); actions = @($deny) }
        @{
            actions = @(
                # Studio accepts loopback requests. Normalize only after the edge checks origin and identity.
                @{ type = 'remove-headers'; config = @{ headers = @('origin', 'x-forwarded-host', 'x-forwarded-port') } }
                @{ type = 'add-headers'; config = @{ headers = @{ host = '127.0.0.1:3100' } } }
            )
        }
    )
}

$policyPath = [IO.Path]::GetTempFileName()
try {
    $policy | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $policyPath -Encoding ASCII
    & ngrok http $studio --inspect=false --log=stdout --traffic-policy-file $policyPath
    if ($LASTEXITCODE -ne 0) { throw "ngrok exited with code $LASTEXITCODE." }
} finally {
    Remove-Item -LiteralPath $policyPath
}
