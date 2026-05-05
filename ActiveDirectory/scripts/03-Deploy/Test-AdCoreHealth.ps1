[CmdletBinding()]
param(
    [string[]]$DomainControllers = @("DC1", "DC2"),
    [string]$ReferenceNtpServer = "time.windows.com,0x9"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Validation replication AD..." -ForegroundColor Cyan
repadmin /replsummary

Write-Host "Validation DNS AD..." -ForegroundColor Cyan
dcdiag /test:DNS /v

Write-Host "Validation services critiques..." -ForegroundColor Cyan
foreach ($dc in $DomainControllers) {
    Write-Host "Verification sur $dc" -ForegroundColor Yellow
    Get-Service -ComputerName $dc -Name NTDS, DNS, KDC, Netlogon | Select-Object MachineName, Name, Status
}

Write-Host "Configuration NTP PDC..." -ForegroundColor Cyan
$pdc = (Get-ADDomain).PDCEmulator
w32tm /config /manualpeerlist:$ReferenceNtpServer /syncfromflags:manual /reliable:yes /update
w32tm /resync /rediscover

Write-Host "Etat NTP actuel:" -ForegroundColor Cyan
w32tm /query /status

Write-Host "Controle coeur AD termine." -ForegroundColor Green
