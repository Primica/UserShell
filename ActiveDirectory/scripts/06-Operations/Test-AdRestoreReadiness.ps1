[CmdletBinding()]
param(
    [string]$BackupPath = "D:\ADBackups"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Verification presence sauvegardes system state..." -ForegroundColor Cyan
if (-not (Test-Path $BackupPath)) {
    throw "Chemin de sauvegarde introuvable: $BackupPath"
}

$backupFiles = Get-ChildItem -Path $BackupPath -File | Sort-Object LastWriteTime -Descending
if ($backupFiles.Count -eq 0) {
    throw "Aucune sauvegarde detectee."
}

$latest = $backupFiles[0]
Write-Host "Derniere sauvegarde: $($latest.FullName)" -ForegroundColor Green
Write-Host "Date: $($latest.LastWriteTime)" -ForegroundColor Green

Write-Host "Rappel test restauration:" -ForegroundColor Yellow
Write-Host "1) Restaurer dans un environnement isole." -ForegroundColor Yellow
Write-Host "2) Verifier objets AD critiques (users/groups/GPO)." -ForegroundColor Yellow
Write-Host "3) Documenter RTO/RPO observe." -ForegroundColor Yellow
