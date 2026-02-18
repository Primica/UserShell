#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    UserShell - Shell pour la gestion des utilisateurs et groupes locaux

.DESCRIPTION
    Outil en ligne de commande pour administrer les utilisateurs
    et groupes locaux Windows. Necessite des privileges administrateur.

.NOTES
    Version: 1.0
    Auteur: Primica
    Date: 2026
#>

param(
    [switch]$Debug
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptPath "Modules"
$LogsPath = Join-Path $ScriptPath "Logs"
$LogFile = Join-Path $LogsPath "usershell_$(Get-Date -Format 'yyyyMMdd').log"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "ERREUR: Ce script necessite des privileges administrateur." -ForegroundColor Red
    Write-Host "Veuillez executer PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

if ($PSVersionTable.PSVersion.Major -lt 5)
{
    Write-Host "ERREUR: PowerShell 5.1 ou superieur est requis." -ForegroundColor Red
    Write-Host "Version actuelle: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $LogsPath))
{
    New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
}

try
{
    Import-Module (Join-Path $ModulesPath "Logger.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "TomlParser.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "UserManager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "GroupManager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "ScriptExecutor.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "DumpManager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "ShellCore.psm1") -Force -ErrorAction Stop
} catch
{
    Write-Host "ERREUR: Impossible de charger les modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try
{
    Initialize-Logger -LogFilePath $LogFile

    if ($Debug)
    {
        Set-LogLevel -Level "DEBUG"
        Write-LogInfo "Mode debug active"
    }

    Start-UserShell
} catch
{
    Write-Host "ERREUR CRITIQUE: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
} finally
{
    Write-LogInfo "Fermeture du shell"
}
