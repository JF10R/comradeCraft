# Tests the Battle.net profile API for Forever (profile + /professions). Reads ../.env.
# Usage: pwsh tools/bnet-test.ps1 -Character jhf-mage
param([string]$Character = 'jhf-mage')

$envFile = Join-Path $PSScriptRoot '..\.env'
if (-not (Test-Path $envFile)) { throw ".env introuvable : copier .env.example vers .env" }
$cfg = @{}
Get-Content $envFile | Where-Object { $_ -match '^\s*([A-Z_]+)\s*=\s*(.*)$' } |
  ForEach-Object { $cfg[$Matches[1]] = $Matches[2].Trim() }
if (-not $cfg.BNET_CLIENT_ID -or -not $cfg.BNET_CLIENT_SECRET) { throw "BNET_CLIENT_ID / BNET_CLIENT_SECRET vides dans .env" }

$region = if ($cfg.BNET_REGION) { $cfg.BNET_REGION } else { 'us' }
$ns = if ($cfg.BNET_NAMESPACE) { $cfg.BNET_NAMESPACE } else { "profile-forever-$region" }

$basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($cfg.BNET_CLIENT_ID):$($cfg.BNET_CLIENT_SECRET)"))
$token = (Invoke-RestMethod -Method Post -Uri 'https://oauth.battle.net/token' `
  -Headers @{ Authorization = "Basic $basic" } -Body @{ grant_type = 'client_credentials' }).access_token
$headers = @{ Authorization = "Bearer $token" }

$char = $Character.ToLower()
foreach ($path in @("/profile/wow/character/$char", "/profile/wow/character/$char/professions")) {
  $uri = "https://$region.api.blizzard.com$path`?namespace=$ns"
  Write-Host "== GET $path" -ForegroundColor Cyan
  try {
    Invoke-RestMethod -Uri $uri -Headers $headers | ConvertTo-Json -Depth 8
  } catch {
    Write-Host "HTTP $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
  }
}
