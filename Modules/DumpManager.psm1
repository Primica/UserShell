# Module de dump pour exporter les utilisateurs et groupes en format TOML

function Export-TomlDump
{
    param(
        [string]$OutputPath,
        [switch]$IncludeSystemAccounts,
        [switch]$IncludeBuiltinGroups,
        [string[]]$ExcludeUsers,
        [string[]]$ExcludeGroups
    )

    if ([string]::IsNullOrWhiteSpace($OutputPath))
    {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = "dump_$timestamp.toml"
    }

    # Résoudre le chemin complet
    if (-not [System.IO.Path]::IsPathRooted($OutputPath))
    {
        $OutputPath = Join-Path (Get-Location) $OutputPath
    }

    # Vérifier l'extension
    if ([System.IO.Path]::GetExtension($OutputPath) -ne '.toml')
    {
        $OutputPath += '.toml'
    }

    Write-LogInfo "Démarrage du dump vers: $OutputPath"

    try
    {
        # Construire le contenu TOML
        $tomlContent = @()

        # En-tête
        $tomlContent += "# UserShell TOML Dump"
        $tomlContent += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $tomlContent += "# Computer: $env:COMPUTERNAME"
        $tomlContent += ""
        $tomlContent += "# This file can be used with 'source' command to recreate this configuration"
        $tomlContent += "# WARNING: Passwords are not exported and will need to be set manually"
        $tomlContent += ""

        # Récupérer tous les utilisateurs
        $users = Get-LocalUser -ErrorAction Stop
        $exportedUsersCount = 0

        # Filtrer les utilisateurs système si nécessaire
        if (-not $IncludeSystemAccounts)
        {
            $systemAccounts = @('Administrator', 'Guest', 'DefaultAccount', 'WDAGUtilityAccount', 'Administrateur', 'Invité')
            $users = $users | Where-Object { $systemAccounts -notcontains $_.Name -and -not $_.Name.StartsWith('_') }
        }

        # Exclure les utilisateurs spécifiés
        if ($ExcludeUsers -and $ExcludeUsers.Count -gt 0)
        {
            $users = $users | Where-Object { $ExcludeUsers -notcontains $_.Name }
        }

        if ($users.Count -gt 0)
        {
            $tomlContent += "# ============================================"
            $tomlContent += "# USERS ($($users.Count))"
            $tomlContent += "# ============================================"
            $tomlContent += ""

            foreach ($user in $users)
            {
                $userToml = Export-UserToToml -User $user
                $tomlContent += $userToml
                $tomlContent += ""
                $exportedUsersCount++
            }
        }

        # Récupérer tous les groupes
        $groups = Get-LocalGroup -ErrorAction Stop
        $exportedGroupsCount = 0

        # Filtrer les groupes système si nécessaire
        if (-not $IncludeBuiltinGroups)
        {
            $builtinGroups = @(
                'Administrators', 'Users', 'Guests', 'Power Users', 'Remote Desktop Users',
                'Backup Operators', 'Replicator', 'Network Configuration Operators',
                'Performance Monitor Users', 'Performance Log Users', 'Distributed COM Users',
                'IIS_IUSRS', 'Cryptographic Operators', 'Event Log Readers',
                'Certificate Service DCOM Access', 'RDS Remote Access Servers',
                'RDS Endpoint Servers', 'RDS Management Servers', 'Hyper-V Administrators',
                'Access Control Assistance Operators', 'Remote Management Users',
                'System Managed Accounts Group', 'Storage Replica Administrators',
                'Administrateurs', 'Utilisateurs', 'Invités', 'Utilisateurs du Bureau à distance',
                'Opérateurs de sauvegarde', 'Utilisateurs avec pouvoir'
            )
            $groups = $groups | Where-Object { $builtinGroups -notcontains $_.Name }
        }

        # Exclure les groupes spécifiés
        if ($ExcludeGroups -and $ExcludeGroups.Count -gt 0)
        {
            $groups = $groups | Where-Object { $ExcludeGroups -notcontains $_.Name }
        }

        if ($groups.Count -gt 0)
        {
            $tomlContent += "# ============================================"
            $tomlContent += "# GROUPS ($($groups.Count))"
            $tomlContent += "# ============================================"
            $tomlContent += ""

            foreach ($group in $groups)
            {
                $groupToml = Export-GroupToToml -Group $group
                $tomlContent += $groupToml
                $tomlContent += ""
                $exportedGroupsCount++
            }
        }

        # Écrire le fichier
        $tomlContent -join "`n" | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

        Write-LogSuccess "Dump créé avec succès: $OutputPath"
        Write-Host "`nStatistiques du dump:" -ForegroundColor Cyan
        Write-Host "  Utilisateurs exportés: $exportedUsersCount" -ForegroundColor Green
        Write-Host "  Groupes exportés:      $exportedGroupsCount" -ForegroundColor Green
        Write-Host "  Fichier:               $OutputPath" -ForegroundColor Yellow

        return $true

    } catch
    {
        Write-LogError "Erreur lors du dump: $($_.Exception.Message)"
        return $false
    }
}

function Export-UserToToml
{
    param(
        [Parameter(Mandatory)]
        $User
    )

    $lines = @()
    $lines += "[[users]]"
    $lines += "name = `"$($User.Name)`""

    # Note sur le mot de passe
    $lines += "# password = `"CHANGE_ME`"  # Password must be set manually"

    if (-not [string]::IsNullOrWhiteSpace($User.FullName))
    {
        $lines += "fullname = `"$($User.FullName)`""
    }

    if (-not [string]::IsNullOrWhiteSpace($User.Description))
    {
        $escapedDesc = $User.Description -replace '"', '\"'
        $lines += "description = `"$escapedDesc`""
    }

    $lines += "password_never_expires = $($User.PasswordExpires -eq $false)".ToLower()
    $lines += "cannot_change_password = $($User.UserMayChangePassword -eq $false)".ToLower()

    # Récupérer les groupes de l'utilisateur
    try
    {
        $userGroups = Get-LocalGroup -ErrorAction SilentlyContinue | Where-Object {
            try
            {
                $members = Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue
                $members.Name -contains "$env:COMPUTERNAME\$($User.Name)" -or $members.Name -contains $User.Name
            } catch
            {
                $false
            }
        }

        if ($userGroups -and $userGroups.Count -gt 0)
        {
            $groupNames = ($userGroups.Name | ForEach-Object { "`"$_`"" }) -join ", "
            $lines += "groups = [$groupNames]"
        }
    } catch
    {
        # Ignorer les erreurs de récupération des groupes
    }

    # Ajouter un commentaire sur l'état
    if (-not $User.Enabled)
    {
        $lines += "# NOTE: This account is currently DISABLED"
        $lines += "# action = `"enable`"  # Uncomment to enable on import"
    }

    return $lines
}

function Export-GroupToToml
{
    param(
        [Parameter(Mandatory)]
        $Group
    )

    $lines = @()
    $lines += "[[groups]]"
    $lines += "name = `"$($Group.Name)`""

    if (-not [string]::IsNullOrWhiteSpace($Group.Description))
    {
        $escapedDesc = $Group.Description -replace '"', '\"'
        $lines += "description = `"$escapedDesc`""
    }

    # Récupérer les membres du groupe
    try
    {
        $members = Get-LocalGroupMember -Group $Group.Name -ErrorAction SilentlyContinue

        if ($members -and $members.Count -gt 0)
        {
            # Extraire seulement le nom d'utilisateur (sans le domaine/ordinateur)
            $memberNames = $members | ForEach-Object {
                $name = $_.Name
                if ($name.Contains('\'))
                {
                    $name = $name.Split('\')[-1]
                }
                "`"$name`""
            }

            $memberList = $memberNames -join ", "
            $lines += "members = [$memberList]"
        } else
        {
            $lines += "# members = []  # No members"
        }
    } catch
    {
        $lines += "# members = []  # Could not retrieve members"
    }

    return $lines
}

function Export-SelectiveTomlDump
{
    param(
        [string]$OutputPath,
        [string[]]$IncludeUsers,
        [string[]]$IncludeGroups
    )

    if ([string]::IsNullOrWhiteSpace($OutputPath))
    {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = "dump_selective_$timestamp.toml"
    }

    # Résoudre le chemin complet
    if (-not [System.IO.Path]::IsPathRooted($OutputPath))
    {
        $OutputPath = Join-Path (Get-Location) $OutputPath
    }

    # Vérifier l'extension
    if ([System.IO.Path]::GetExtension($OutputPath) -ne '.toml')
    {
        $OutputPath += '.toml'
    }

    Write-LogInfo "Démarrage du dump sélectif vers: $OutputPath"

    try
    {
        $tomlContent = @()

        # En-tête
        $tomlContent += "# UserShell TOML Selective Dump"
        $tomlContent += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $tomlContent += "# Computer: $env:COMPUTERNAME"
        $tomlContent += ""

        $exportedUsersCount = 0
        $exportedGroupsCount = 0

        # Export des utilisateurs spécifiés
        if ($IncludeUsers -and $IncludeUsers.Count -gt 0)
        {
            $tomlContent += "# ============================================"
            $tomlContent += "# SELECTED USERS"
            $tomlContent += "# ============================================"
            $tomlContent += ""

            foreach ($userName in $IncludeUsers)
            {
                try
                {
                    $user = Get-LocalUser -Name $userName -ErrorAction Stop
                    $userToml = Export-UserToToml -User $user
                    $tomlContent += $userToml
                    $tomlContent += ""
                    $exportedUsersCount++
                } catch
                {
                    Write-LogWarning "Utilisateur '$userName' non trouvé"
                    $tomlContent += "# User '$userName' not found"
                    $tomlContent += ""
                }
            }
        }

        # Export des groupes spécifiés
        if ($IncludeGroups -and $IncludeGroups.Count -gt 0)
        {
            $tomlContent += "# ============================================"
            $tomlContent += "# SELECTED GROUPS"
            $tomlContent += "# ============================================"
            $tomlContent += ""

            foreach ($groupName in $IncludeGroups)
            {
                try
                {
                    $group = Get-LocalGroup -Name $groupName -ErrorAction Stop
                    $groupToml = Export-GroupToToml -Group $group
                    $tomlContent += $groupToml
                    $tomlContent += ""
                    $exportedGroupsCount++
                } catch
                {
                    Write-LogWarning "Groupe '$groupName' non trouvé"
                    $tomlContent += "# Group '$groupName' not found"
                    $tomlContent += ""
                }
            }
        }

        # Écrire le fichier
        $tomlContent -join "`n" | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

        Write-LogSuccess "Dump sélectif créé avec succès: $OutputPath"
        Write-Host "`nStatistiques du dump:" -ForegroundColor Cyan
        Write-Host "  Utilisateurs exportés: $exportedUsersCount" -ForegroundColor Green
        Write-Host "  Groupes exportés:      $exportedGroupsCount" -ForegroundColor Green
        Write-Host "  Fichier:               $OutputPath" -ForegroundColor Yellow

        return $true

    } catch
    {
        Write-LogError "Erreur lors du dump sélectif: $($_.Exception.Message)"
        return $false
    }
}

function Show-DumpHelp
{
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Aide - Commandes de Dump TOML" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Write-Host "`nDump complet:" -ForegroundColor Yellow
    Write-Host "  dump                          - Dump de tous les utilisateurs/groupes non-système"
    Write-Host "  dump <fichier>                - Dump vers un fichier spécifique"
    Write-Host "  dump <fichier> --all          - Inclure les comptes système"
    Write-Host "  dump <fichier> --system       - Inclure comptes et groupes système"

    Write-Host "`nDump sélectif:" -ForegroundColor Yellow
    Write-Host "  dump --users user1,user2      - Dump uniquement certains utilisateurs"
    Write-Host "  dump --groups group1,group2   - Dump uniquement certains groupes"

    Write-Host "`nExemples:" -ForegroundColor Yellow
    Write-Host "  dump                          - Dump automatique avec timestamp"
    Write-Host "  dump backup.toml              - Dump vers backup.toml"
    Write-Host "  dump config.toml --all        - Dump complet incluant système"
    Write-Host "  dump --users alice,bob        - Dump uniquement alice et bob"

    Write-Host "`nNotes:" -ForegroundColor Yellow
    Write-Host "  - Les mots de passe ne sont PAS exportés (sécurité)"
    Write-Host "  - Vous devrez définir les mots de passe manuellement"
    Write-Host "  - Les comptes désactivés sont marqués avec un commentaire"
    Write-Host "  - Le fichier peut être utilisé avec 'source <fichier>'"

    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

Export-ModuleMember -Function Export-TomlDump, Export-SelectiveTomlDump, Show-DumpHelp
