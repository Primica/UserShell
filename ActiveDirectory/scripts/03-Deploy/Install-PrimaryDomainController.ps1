[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFqdn,

    [Parameter(Mandatory = $true)]
    [string]$NetbiosName,

    [Parameter(Mandatory = $true)]
    [SecureString]$SafeModeAdministratorPassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment -ErrorAction Stop

Install-ADDSForest `
    -DomainName $DomainFqdn `
    -DomainNetbiosName $NetbiosName `
    -InstallDNS `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
    -Force:$true

Write-Host "DC primaire promu. Un redemarrage est attendu." -ForegroundColor Green
