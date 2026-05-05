[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainDn,

    [string]$PrimarySiteName = "HQ",
    [string]$SecondarySiteName = "DR",
    [string]$PrimarySubnet = "10.0.0.0/24",
    [string]$SecondarySubnet = "10.0.1.0/24"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

function Ensure-OrganizationalUnit {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $dn = "OU=$Name,$Path"
    $existing = Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$dn)" -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true | Out-Null
        Write-Host "OU creee: $dn" -ForegroundColor Green
    }
    else {
        Write-Host "OU deja presente: $dn" -ForegroundColor Yellow
    }
}

function Ensure-Group {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet("Global", "DomainLocal", "Universal")] [string]$Scope,
        [string]$Description = ""
    )

    $existing = Get-ADGroup -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        New-ADGroup -Name $Name -GroupCategory Security -GroupScope $Scope -Path $Path -Description $Description | Out-Null
        Write-Host "Groupe cree: $Name" -ForegroundColor Green
    }
    else {
        Write-Host "Groupe deja present: $Name" -ForegroundColor Yellow
    }
}

Write-Host "Provisioning architecture AD cible..." -ForegroundColor Cyan

$rootOu = "OU=CORP,$DomainDn"
Ensure-OrganizationalUnit -Name "CORP" -Path $DomainDn

# Tiering administratif
Ensure-OrganizationalUnit -Name "Tier0" -Path $rootOu
Ensure-OrganizationalUnit -Name "Tier1" -Path $rootOu
Ensure-OrganizationalUnit -Name "Tier2" -Path $rootOu

# Objets d'identite
Ensure-OrganizationalUnit -Name "Users" -Path $rootOu
Ensure-OrganizationalUnit -Name "Groups" -Path $rootOu
Ensure-OrganizationalUnit -Name "ServiceAccounts" -Path $rootOu
Ensure-OrganizationalUnit -Name "Workstations" -Path $rootOu
Ensure-OrganizationalUnit -Name "Servers" -Path $rootOu

# Sous-OUs groupes (AGDLP)
$groupsOu = "OU=Groups,$rootOu"
Ensure-OrganizationalUnit -Name "Global" -Path $groupsOu
Ensure-OrganizationalUnit -Name "DomainLocal" -Path $groupsOu
Ensure-OrganizationalUnit -Name "Admin" -Path $groupsOu

$globalOu = "OU=Global,$groupsOu"
$domainLocalOu = "OU=DomainLocal,$groupsOu"
$adminOu = "OU=Admin,$groupsOu"

# Groupes d'administration
Ensure-Group -Name "ADM_Tier0_AD" -Path $adminOu -Scope Global -Description "Administrateurs AD Tier0"
Ensure-Group -Name "ADM_Tier1_Servers" -Path $adminOu -Scope Global -Description "Administrateurs serveurs Tier1"
Ensure-Group -Name "ADM_Tier2_Helpdesk" -Path $adminOu -Scope Global -Description "Support utilisateurs Tier2"

# Groupes metier globaux (exemples)
Ensure-Group -Name "GG_IT" -Path $globalOu -Scope Global -Description "Equipe IT"
Ensure-Group -Name "GG_HR" -Path $globalOu -Scope Global -Description "Equipe RH"

# Groupes locaux de domaine pour ACL (exemples)
Ensure-Group -Name "DL_FileSrv_HR_Modify" -Path $domainLocalOu -Scope DomainLocal -Description "Acces modification partage RH"
Ensure-Group -Name "DL_FileSrv_IT_Full" -Path $domainLocalOu -Scope DomainLocal -Description "Acces full partage IT"

# Liaison AGDLP (exemples)
Add-ADGroupMember -Identity "DL_FileSrv_HR_Modify" -Members "GG_HR" -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "DL_FileSrv_IT_Full" -Members "GG_IT" -ErrorAction SilentlyContinue

# Sites AD
if (-not (Get-ADReplicationSite -Filter "Name -eq '$PrimarySiteName'" -ErrorAction SilentlyContinue)) {
    New-ADReplicationSite -Name $PrimarySiteName | Out-Null
}
if (-not (Get-ADReplicationSite -Filter "Name -eq '$SecondarySiteName'" -ErrorAction SilentlyContinue)) {
    New-ADReplicationSite -Name $SecondarySiteName | Out-Null
}

if (-not (Get-ADReplicationSubnet -Filter "Name -eq '$PrimarySubnet'" -ErrorAction SilentlyContinue)) {
    New-ADReplicationSubnet -Name $PrimarySubnet -Site $PrimarySiteName | Out-Null
}
if (-not (Get-ADReplicationSubnet -Filter "Name -eq '$SecondarySubnet'" -ErrorAction SilentlyContinue)) {
    New-ADReplicationSubnet -Name $SecondarySubnet -Site $SecondarySiteName | Out-Null
}

Write-Host "Architecture AD cible provisionnee." -ForegroundColor Green
