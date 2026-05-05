[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFqdn,

    [string]$RootOuDn
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

if (-not $RootOuDn) {
    $domain = Get-ADDomain
    $RootOuDn = "OU=CORP,$($domain.DistinguishedName)"
}

function Ensure-Gpo {
    param([string]$Name)
    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $gpo) {
        $gpo = New-GPO -Name $Name -Comment "Provisioned by AD governance baseline"
        Write-Host "GPO creee: $Name" -ForegroundColor Green
    }
    else {
        Write-Host "GPO deja presente: $Name" -ForegroundColor Yellow
    }
    return $gpo
}

function Ensure-GpoLink {
    param(
        [string]$GpoName,
        [string]$TargetDn
    )
    $existing = Get-GPInheritance -Target $TargetDn
    if ($existing.GpoLinks.DisplayName -notcontains $GpoName) {
        New-GPLink -Name $GpoName -Target $TargetDn -LinkEnabled Yes | Out-Null
        Write-Host "Lien GPO cree: $GpoName -> $TargetDn" -ForegroundColor Green
    }
}

$gpoPassword = Ensure-Gpo -Name "GPO_Domain_PasswordAndLockout"
$gpoWorkstation = Ensure-Gpo -Name "GPO_Workstations_Hardening"
$gpoServer = Ensure-Gpo -Name "GPO_Servers_Hardening"
$gpoAudit = Ensure-Gpo -Name "GPO_Domain_AdvancedAuditing"

# Password / lockout baseline via registry policies (FGPP recommande pour granularite)
Set-GPRegistryValue -Name $gpoPassword.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName "MaximumPasswordAge" -Type DWord -Value 90
Set-GPRegistryValue -Name $gpoPassword.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName "MinimumPasswordLength" -Type DWord -Value 14

# Hardening workstation
Set-GPRegistryValue -Name $gpoWorkstation.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" -ValueName "Deny_All" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoWorkstation.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows\System" -ValueName "DisableCMD" -Type DWord -Value 1

# Hardening servers
Set-GPRegistryValue -Name $gpoServer.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDenyTSConnections" -Type DWord -Value 1

# Advanced auditing
Set-GPRegistryValue -Name $gpoAudit.DisplayName -Key "HKLM\Software\Policies\Microsoft\Windows\EventLog\Security" -ValueName "MaxSize" -Type DWord -Value 1048576

Ensure-GpoLink -GpoName $gpoPassword.DisplayName -TargetDn (Get-ADDomain).DistinguishedName
Ensure-GpoLink -GpoName $gpoAudit.DisplayName -TargetDn (Get-ADDomain).DistinguishedName
Ensure-GpoLink -GpoName $gpoWorkstation.DisplayName -TargetDn "OU=Workstations,$RootOuDn"
Ensure-GpoLink -GpoName $gpoServer.DisplayName -TargetDn "OU=Servers,$RootOuDn"

Write-Host "Baseline GPO appliquee." -ForegroundColor Green
