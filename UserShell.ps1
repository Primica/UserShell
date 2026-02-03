#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    UserShell - Shell pour la gestion des utilisateurs et groupes locaux

.DESCRIPTION
    Outil en ligne de commande avec architecture POO pour administrer les utilisateurs
    et groupes locaux Windows. Necessite des privileges administrateur.

.NOTES
    Version: 1.0
    Auteur: UserShell
    Date: 2024
#>

param(
    [switch]$Debug
)

# Configuration des chemins
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptPath "Modules"
$LogsPath = Join-Path $ScriptPath "Logs"
$LogFile = Join-Path $LogsPath "usershell_$(Get-Date -Format 'yyyyMMdd').log"

# Verification des privileges administrateur
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "ERREUR: Ce script necessite des privileges administrateur." -ForegroundColor Red
    Write-Host "Veuillez executer PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

# Verification de la version PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5)
{
    Write-Host "ERREUR: PowerShell 5.1 ou superieur est requis." -ForegroundColor Red
    Write-Host "Version actuelle: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}

# Creation du repertoire de logs si necessaire
if (-not (Test-Path $LogsPath))
{
    New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
}

# Chargement des modules
try
{
    Import-Module (Join-Path $ModulesPath "Logger.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "UserManager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "GroupManager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $ModulesPath "ShellCore.psm1") -Force -ErrorAction Stop
} catch
{
    Write-Host "ERREUR: Impossible de charger les modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Demarrage du shell
try
{
    # Initialisation du logger
    Initialize-Logger -LogFilePath $LogFile

    if ($Debug)
    {
        Set-LogLevel -Level "DEBUG"
        Write-LogInfo "Mode debug active"
    }

    # Demarrage du shell
    Start-UserShell
} catch
{
    Write-Host "ERREUR CRITIQUE: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
} finally
{
    # Nettoyage
    Write-LogInfo "Fermeture du shell"
}
