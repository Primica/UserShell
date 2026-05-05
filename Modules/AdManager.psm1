# Module de pilotage Active Directory pour UserShell

Set-StrictMode -Version Latest

function Get-AdBasePath
{
    $projectRoot = Split-Path -Parent $PSScriptRoot
    return Join-Path $projectRoot "ActiveDirectory"
}

function Resolve-AdScriptPath
{
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path (Get-AdBasePath) $RelativePath
    if (-not (Test-Path $path))
    {
        throw "Script AD introuvable: $path"
    }
    return $path
}

function Invoke-AdScript
{
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [hashtable]$Parameters
    )

    $scriptPath = Resolve-AdScriptPath -RelativePath $RelativePath
    Write-Host "Execution: $scriptPath" -ForegroundColor Cyan

    if ($null -eq $Parameters -or $Parameters.Count -eq 0)
    {
        & $scriptPath
    }
    else
    {
        & $scriptPath @Parameters
    }
}

function Show-AdHelp
{
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Aide Active Directory" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ad-help                    - Afficher l'aide AD"
    Write-Host "  ad-paths                   - Afficher les chemins AD du projet"
    Write-Host "  ad-design                  - Provisionner OU/groupes/sites AD"
    Write-Host "  ad-deploy-primary          - Promouvoir le premier DC"
    Write-Host "  ad-deploy-secondary        - Promouvoir le second DC"
    Write-Host "  ad-health                  - Verifier replication/DNS/NTP/services"
    Write-Host "  ad-baseline                - Creer et lier la baseline GPO"
    Write-Host "  ad-delegate                - Appliquer les delegations OU"
    Write-Host "  ad-migrate                 - Migrer les utilisateurs via CSV"
    Write-Host "  ad-validate                - Executer la recette pilote"
    Write-Host "  ad-audit                   - Lancer l'audit trimestriel"
    Write-Host "  ad-restore-check           - Verifier la readiness restauration"
    Write-Host "  ad-auto-core               - Enchainer design + baseline + delegation + health"
    Write-Host "  ad-full-deploy             - Assistant complet guide avec confirmations et log"
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Show-AdPaths
{
    $base = Get-AdBasePath
    Write-Host "`nBase AD: $base" -ForegroundColor Yellow
    Write-Host "Scripts: $(Join-Path $base 'scripts')" -ForegroundColor Yellow
    Write-Host "Docs:    $(Join-Path $base 'docs')" -ForegroundColor Yellow
    Write-Host "Config:  $(Join-Path $base 'config')" -ForegroundColor Yellow
}

function Invoke-AdDesign
{
    $domainDn = Read-Host "Domain DN (ex: DC=corp,DC=contoso,DC=local)"
    if ([string]::IsNullOrWhiteSpace($domainDn)) { Write-LogError "Domain DN requis"; return }

    $primarySite = Read-Host "Site principal [HQ]"
    if ([string]::IsNullOrWhiteSpace($primarySite)) { $primarySite = "HQ" }
    $secondarySite = Read-Host "Site secondaire [DR]"
    if ([string]::IsNullOrWhiteSpace($secondarySite)) { $secondarySite = "DR" }
    $primarySubnet = Read-Host "Subnet site principal [10.0.0.0/24]"
    if ([string]::IsNullOrWhiteSpace($primarySubnet)) { $primarySubnet = "10.0.0.0/24" }
    $secondarySubnet = Read-Host "Subnet site secondaire [10.0.1.0/24]"
    if ([string]::IsNullOrWhiteSpace($secondarySubnet)) { $secondarySubnet = "10.0.1.0/24" }

    Invoke-AdScript -RelativePath "scripts\02-Design\New-AdTargetArchitecture.ps1" -Parameters @{
        DomainDn = $domainDn
        PrimarySiteName = $primarySite
        SecondarySiteName = $secondarySite
        PrimarySubnet = $primarySubnet
        SecondarySubnet = $secondarySubnet
    }
}

function Invoke-AdDeployPrimary
{
    $domainFqdn = Read-Host "Domaine FQDN (ex: corp.contoso.local)"
    $netbios = Read-Host "NetBIOS (ex: CORP)"
    if ([string]::IsNullOrWhiteSpace($domainFqdn) -or [string]::IsNullOrWhiteSpace($netbios))
    {
        Write-LogError "Domain FQDN et NetBIOS sont requis"
        return
    }

    $dsrm = Read-Host "Mot de passe DSRM" -AsSecureString
    Invoke-AdScript -RelativePath "scripts\03-Deploy\Install-PrimaryDomainController.ps1" -Parameters @{
        DomainFqdn = $domainFqdn
        NetbiosName = $netbios
        SafeModeAdministratorPassword = $dsrm
    }
}

function Invoke-AdDeploySecondary
{
    $domainFqdn = Read-Host "Domaine FQDN (ex: corp.contoso.local)"
    if ([string]::IsNullOrWhiteSpace($domainFqdn)) { Write-LogError "Domain FQDN requis"; return }

    $siteName = Read-Host "Nom du site secondaire [DR]"
    if ([string]::IsNullOrWhiteSpace($siteName)) { $siteName = "DR" }

    $credential = Get-Credential -Message "Credential de promotion du DC secondaire"
    $dsrm = Read-Host "Mot de passe DSRM" -AsSecureString

    Invoke-AdScript -RelativePath "scripts\03-Deploy\Install-SecondaryDomainController.ps1" -Parameters @{
        DomainFqdn = $domainFqdn
        DomainCredential = $credential
        SafeModeAdministratorPassword = $dsrm
        SiteName = $siteName
    }
}

function Invoke-AdHealth
{
    $dcs = Read-Host "Liste des DC (separes par ,) [DC1,DC2]"
    if ([string]::IsNullOrWhiteSpace($dcs)) { $dcArray = @("DC1", "DC2") } else { $dcArray = $dcs -split ',' | ForEach-Object { $_.Trim() } }
    $ntp = Read-Host "Serveur NTP reference [time.windows.com,0x9]"
    if ([string]::IsNullOrWhiteSpace($ntp)) { $ntp = "time.windows.com,0x9" }

    Invoke-AdScript -RelativePath "scripts\03-Deploy\Test-AdCoreHealth.ps1" -Parameters @{
        DomainControllers = $dcArray
        ReferenceNtpServer = $ntp
    }
}

function Invoke-AdBaseline
{
    $domainFqdn = Read-Host "Domaine FQDN"
    if ([string]::IsNullOrWhiteSpace($domainFqdn)) { Write-LogError "Domaine requis"; return }

    $rootOuDn = Read-Host "Root OU DN [OU=CORP,...] (optionnel)"
    $params = @{ DomainFqdn = $domainFqdn }
    if (-not [string]::IsNullOrWhiteSpace($rootOuDn)) { $params["RootOuDn"] = $rootOuDn }

    Invoke-AdScript -RelativePath "scripts\04-Governance\Set-AdSecurityBaseline.ps1" -Parameters $params
}

function Invoke-AdDelegate
{
    $domainDn = Read-Host "Domain DN (ex: DC=corp,DC=contoso,DC=local)"
    if ([string]::IsNullOrWhiteSpace($domainDn)) { Write-LogError "Domain DN requis"; return }

    Invoke-AdScript -RelativePath "scripts\04-Governance\Set-AdOuDelegation.ps1" -Parameters @{
        DomainDn = $domainDn
    }
}

function Invoke-AdMigrate
{
    $csvPath = Read-Host "Chemin CSV migration"
    $usersOuDn = Read-Host "OU cible utilisateurs (DN)"
    if ([string]::IsNullOrWhiteSpace($csvPath) -or [string]::IsNullOrWhiteSpace($usersOuDn))
    {
        Write-LogError "CSV et Users OU DN sont requis"
        return
    }

    $whatIfAnswer = Read-Host "Mode simulation WhatIf ? (O/N) [O]"
    $whatIfMode = $true
    if ($whatIfAnswer -eq 'N' -or $whatIfAnswer -eq 'n') { $whatIfMode = $false }

    $params = @{
        UsersCsvPath = $csvPath
        UsersOuDn = $usersOuDn
    }
    if ($whatIfMode) { $params["WhatIfMode"] = $true }

    Invoke-AdScript -RelativePath "scripts\05-Migration\Invoke-AdMigration.ps1" -Parameters $params
}

function Invoke-AdValidate
{
    $pilotUserSam = Read-Host "Compte pilote SamAccountName"
    if ([string]::IsNullOrWhiteSpace($pilotUserSam)) { Write-LogError "Compte pilote requis"; return }

    $pilotComputer = Read-Host "Machine pilote [$env:COMPUTERNAME]"
    if ([string]::IsNullOrWhiteSpace($pilotComputer)) { $pilotComputer = $env:COMPUTERNAME }

    $primaryDc = Read-Host "DC principal [DC1]"
    if ([string]::IsNullOrWhiteSpace($primaryDc)) { $primaryDc = "DC1" }

    Invoke-AdScript -RelativePath "scripts\05-Migration\Test-AdPilotValidation.ps1" -Parameters @{
        PilotUserSam = $pilotUserSam
        PilotComputer = $pilotComputer
        PrimaryDcName = $primaryDc
    }
}

function Invoke-AdAudit
{
    $days = Read-Host "Seuil inactivite utilisateurs en jours [90]"
    if ([string]::IsNullOrWhiteSpace($days)) { $days = 90 }
    Invoke-AdScript -RelativePath "scripts\06-Operations\Invoke-AdQuarterlyAudit.ps1" -Parameters @{
        InactiveUserDays = [int]$days
    }
}

function Invoke-AdRestoreCheck
{
    $backupPath = Read-Host "Chemin de sauvegarde [D:\ADBackups]"
    if ([string]::IsNullOrWhiteSpace($backupPath)) { $backupPath = "D:\ADBackups" }

    Invoke-AdScript -RelativePath "scripts\06-Operations\Test-AdRestoreReadiness.ps1" -Parameters @{
        BackupPath = $backupPath
    }
}

function Invoke-AdAutoCore
{
    Write-Host "`nExecution automatique du socle AD (design -> baseline -> delegation -> health)" -ForegroundColor Cyan
    Invoke-AdDesign
    Invoke-AdBaseline
    Invoke-AdDelegate
    Invoke-AdHealth
}

function Invoke-AdStepWithConfirmation
{
    param(
        [Parameter(Mandatory = $true)][string]$StepName,
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$LogFile
    )

    $confirm = Read-Host "Executer l'etape '$StepName' ? (O/N) [O]"
    if ($confirm -eq 'N' -or $confirm -eq 'n')
    {
        $line = "$(Get-Date -Format o) | SKIPPED | $StepName"
        Add-Content -Path $LogFile -Value $line
        Write-Host "Etape ignoree: $StepName" -ForegroundColor Yellow
        return
    }

    try
    {
        & $Action
        $line = "$(Get-Date -Format o) | OK | $StepName"
        Add-Content -Path $LogFile -Value $line
        Write-Host "Etape terminee: $StepName" -ForegroundColor Green
    } catch
    {
        $line = "$(Get-Date -Format o) | ERROR | $StepName | $($_.Exception.Message)"
        Add-Content -Path $LogFile -Value $line
        Write-LogError "Echec etape '$StepName': $($_.Exception.Message)"

        $continue = Read-Host "Continuer malgre l'erreur ? (O/N) [N]"
        if ($continue -ne 'O' -and $continue -ne 'o')
        {
            throw
        }
    }
}

function Invoke-AdFullDeploy
{
    Write-Host "`nAssistant de deploiement AD complet" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $dryRunAnswer = Read-Host "Mode simulation global (sans migration reelle) ? (O/N) [O]"
    $isDryRun = $true
    if ($dryRunAnswer -eq 'N' -or $dryRunAnswer -eq 'n') { $isDryRun = $false }

    $projectRoot = Split-Path -Parent $PSScriptRoot
    $logsDir = Join-Path $projectRoot "Logs"
    if (-not (Test-Path $logsDir))
    {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    $logFile = Join-Path $logsDir ("ad-full-deploy-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    Add-Content -Path $logFile -Value "$(Get-Date -Format o) | START | ad-full-deploy | dry-run=$isDryRun"
    Write-Host "Journal: $logFile" -ForegroundColor Yellow

    Invoke-AdStepWithConfirmation -StepName "Deploiement DC primaire" -LogFile $logFile -Action { Invoke-AdDeployPrimary }
    Invoke-AdStepWithConfirmation -StepName "Deploiement DC secondaire" -LogFile $logFile -Action { Invoke-AdDeploySecondary }
    Invoke-AdStepWithConfirmation -StepName "Validation sante coeur AD" -LogFile $logFile -Action { Invoke-AdHealth }
    Invoke-AdStepWithConfirmation -StepName "Provisioning architecture cible (OU/groupes/sites)" -LogFile $logFile -Action { Invoke-AdDesign }
    Invoke-AdStepWithConfirmation -StepName "Application baseline GPO" -LogFile $logFile -Action { Invoke-AdBaseline }
    Invoke-AdStepWithConfirmation -StepName "Application delegations OU" -LogFile $logFile -Action { Invoke-AdDelegate }

    if ($isDryRun)
    {
        Invoke-AdStepWithConfirmation -StepName "Migration pilote (simulation WhatIf)" -LogFile $logFile -Action {
            Write-Host "La migration sera forcee en simulation (WhatIf)." -ForegroundColor Yellow
            $csvPath = Read-Host "Chemin CSV migration"
            $usersOuDn = Read-Host "OU cible utilisateurs (DN)"
            if ([string]::IsNullOrWhiteSpace($csvPath) -or [string]::IsNullOrWhiteSpace($usersOuDn))
            {
                throw "CSV et Users OU DN requis pour la simulation."
            }
            Invoke-AdScript -RelativePath "scripts\05-Migration\Invoke-AdMigration.ps1" -Parameters @{
                UsersCsvPath = $csvPath
                UsersOuDn = $usersOuDn
                WhatIfMode = $true
            }
        }
    }
    else
    {
        Invoke-AdStepWithConfirmation -StepName "Migration pilote" -LogFile $logFile -Action { Invoke-AdMigrate }
    }

    Invoke-AdStepWithConfirmation -StepName "Recette technique pilote" -LogFile $logFile -Action { Invoke-AdValidate }
    Invoke-AdStepWithConfirmation -StepName "Audit post-deploiement" -LogFile $logFile -Action { Invoke-AdAudit }
    Invoke-AdStepWithConfirmation -StepName "Controle readiness restauration" -LogFile $logFile -Action { Invoke-AdRestoreCheck }

    Add-Content -Path $logFile -Value "$(Get-Date -Format o) | END | ad-full-deploy"
    Write-Host "`nDeploiement guide termine." -ForegroundColor Green
}

Export-ModuleMember -Function Show-AdHelp, Show-AdPaths, Invoke-AdDesign, Invoke-AdDeployPrimary, Invoke-AdDeploySecondary, Invoke-AdHealth, Invoke-AdBaseline, Invoke-AdDelegate, Invoke-AdMigrate, Invoke-AdValidate, Invoke-AdAudit, Invoke-AdRestoreCheck, Invoke-AdAutoCore, Invoke-AdFullDeploy
