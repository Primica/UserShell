[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainDn
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

$rootOu = "OU=CORP,$DomainDn"
$usersOu = "OU=Users,$rootOu"
$workstationsOu = "OU=Workstations,$rootOu"

Write-Host "Application des delegations OU..." -ForegroundColor Cyan

# A executer avec un compte Tier0.
# Ces delegations s'appuient sur les cmdlets ADDS (granulaires) et dsacls pour certains droits.

# Delegation helpdesk Tier2 sur comptes utilisateurs standards
dsacls $usersOu /G "CORP\ADM_Tier2_Helpdesk:CA;Reset Password;user"
dsacls $usersOu /G "CORP\ADM_Tier2_Helpdesk:WP;lockoutTime;user"
dsacls $usersOu /G "CORP\ADM_Tier2_Helpdesk:RPWP;pwdLastSet;user"

# Delegation Tier1 pour joindre des postes / gerer objets ordinateurs
dsacls $workstationsOu /G "CORP\ADM_Tier1_Servers:CCDC;computer"
dsacls $workstationsOu /G "CORP\ADM_Tier1_Servers:RPWP;description;computer"

Write-Host "Delegations OU appliquees." -ForegroundColor Green
