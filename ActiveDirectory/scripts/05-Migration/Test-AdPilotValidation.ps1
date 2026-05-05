[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PilotUserSam,

    [string]$PilotComputer = $env:COMPUTERNAME,
    [string]$ExpectedGpoKeyword = "GPO_",
    [string]$PrimaryDcName = "DC1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Validation compte pilote..." -ForegroundColor Cyan
$user = Get-ADUser -Identity $PilotUserSam -Properties Enabled, LastLogonDate
if (-not $user.Enabled) {
    throw "Le compte pilote est desactive: $PilotUserSam"
}

Write-Host "Validation appartenance groupe..." -ForegroundColor Cyan
Get-ADPrincipalGroupMembership -Identity $PilotUserSam | Select-Object Name | Format-Table -AutoSize

Write-Host "Validation GPO appliquees..." -ForegroundColor Cyan
$gpresultFile = Join-Path $env:TEMP "gpresult-$PilotComputer.txt"
gpresult /SCOPE COMPUTER /R > $gpresultFile
$content = Get-Content -Path $gpresultFile -Raw
if ($content -notmatch $ExpectedGpoKeyword) {
    Write-Warning "Aucune GPO attendue detectee avec le mot-cle $ExpectedGpoKeyword"
}

Write-Host "Test de tolerance de panne (verification DC secondaire)..." -ForegroundColor Cyan
$dcList = Get-ADDomainController -Filter *
$secondaryFound = $dcList | Where-Object { $_.HostName -ne $PrimaryDcName -and $_.IsGlobalCatalog }
if ($null -eq $secondaryFound) {
    throw "Aucun DC secondaire GC detecte."
}

Write-Host "Recette pilote terminee avec succes." -ForegroundColor Green
