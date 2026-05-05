[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFqdn,

    [Parameter(Mandatory = $true)]
    [pscredential]$DomainCredential,

    [Parameter(Mandatory = $true)]
    [SecureString]$SafeModeAdministratorPassword,

    [string]$SiteName = "DR"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment -ErrorAction Stop

Install-ADDSDomainController `
    -DomainName $DomainFqdn `
    -Credential $DomainCredential `
    -InstallDNS `
    -SiteName $SiteName `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
    -Force:$true

Write-Host "DC secondaire promu. Un redemarrage est attendu." -ForegroundColor Green
