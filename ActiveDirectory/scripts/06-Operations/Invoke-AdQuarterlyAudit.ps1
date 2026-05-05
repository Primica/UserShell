[CmdletBinding()]
param(
    [int]$InactiveUserDays = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop
Import-Module GroupPolicy -ErrorAction Stop

$reportFolder = Join-Path $PSScriptRoot "..\..\reports"
if (-not (Test-Path $reportFolder)) {
    New-Item -Path $reportFolder -ItemType Directory | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Audit comptes inactifs..." -ForegroundColor Cyan
$inactiveUsers = Search-ADAccount -UsersOnly -AccountInactive -TimeSpan ([TimeSpan]::FromDays($InactiveUserDays))
$inactiveUsers | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path (Join-Path $reportFolder "inactive-users-$stamp.csv")

Write-Host "Audit groupes privilegies..." -ForegroundColor Cyan
$privilegedGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")
$rows = foreach ($group in $privilegedGroups) {
    try {
        Get-ADGroupMember -Identity $group -Recursive | Select-Object @{ Name = "Group"; Expression = { $group } }, Name, SamAccountName, objectClass
    }
    catch {
        Write-Warning "Groupe introuvable ou inaccessible: $group"
    }
}
$rows | Export-Csv -NoTypeInformation -Path (Join-Path $reportFolder "privileged-groups-$stamp.csv")

Write-Host "Export inventaire GPO..." -ForegroundColor Cyan
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime | Export-Csv -NoTypeInformation -Path (Join-Path $reportFolder "gpo-inventory-$stamp.csv")

Write-Host "Audit trimestriel termine. Rapports dans: $reportFolder" -ForegroundColor Green
