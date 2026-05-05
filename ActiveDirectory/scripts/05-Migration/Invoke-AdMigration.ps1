[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UsersCsvPath,

    [Parameter(Mandatory = $true)]
    [string]$UsersOuDn,

    [switch]$WhatIfMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path $UsersCsvPath)) {
    throw "Fichier CSV introuvable: $UsersCsvPath"
}

$rows = Import-Csv -Path $UsersCsvPath
Write-Host "Utilisateurs a migrer: $($rows.Count)" -ForegroundColor Cyan

foreach ($row in $rows) {
    $sam = $row.SamAccountName
    $upn = $row.UserPrincipalName
    $displayName = $row.DisplayName
    $givenName = $row.GivenName
    $surname = $row.Surname
    $description = $row.Description
    $targetGroups = @($row.Groups -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ([string]::IsNullOrWhiteSpace($sam) -or [string]::IsNullOrWhiteSpace($upn)) {
        Write-Warning "Ligne ignoree (SamAccountName/UPN manquant)."
        continue
    }

    $existing = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        $password = ConvertTo-SecureString ("Temp!" + [Guid]::NewGuid().ToString("N").Substring(0, 12)) -AsPlainText -Force

        $params = @{
            SamAccountName = $sam
            UserPrincipalName = $upn
            Name = $displayName
            DisplayName = $displayName
            GivenName = $givenName
            Surname = $surname
            Description = $description
            Path = $UsersOuDn
            AccountPassword = $password
            Enabled = $true
            ChangePasswordAtLogon = $true
        }

        if ($WhatIfMode) {
            Write-Host "[WHATIF] Creation utilisateur: $sam" -ForegroundColor Yellow
        }
        else {
            New-ADUser @params
            Write-Host "Utilisateur cree: $sam" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Utilisateur deja present: $sam" -ForegroundColor Yellow
    }

    foreach ($groupName in $targetGroups) {
        if ($WhatIfMode) {
            Write-Host "[WHATIF] Ajout $sam -> $groupName" -ForegroundColor Yellow
        }
        else {
            Add-ADGroupMember -Identity $groupName -Members $sam -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Migration AD terminee." -ForegroundColor Green
