# Module ShellCore - Moteur principal du shell

$script:Running = $false
$script:Prompt = "UserShell>"

function Start-UserShell
{
    $script:Running = $true
    Show-Banner
    Write-LogInfo "UserShell started"

    while ($script:Running)
    {
        try
        {
            $input = Read-Host $script:Prompt

            if ([string]::IsNullOrWhiteSpace($input))
            {
                continue
            }

            Invoke-ShellCommand -CommandLine $input.Trim()
        } catch
        {
            Write-LogError "Unexpected error: $($_.Exception.Message)"
        }
    }

    Write-LogInfo "UserShell stopped"
}

function Stop-UserShell
{
    $script:Running = $false
    Write-Host "`nAu revoir." -ForegroundColor Cyan
}

function Show-Banner
{
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    UserShell - Gestion Locale v1.0    " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Tapez 'help' pour afficher l'aide`n" -ForegroundColor Yellow
}

function Invoke-ShellCommand
{
    param([string]$CommandLine)

    $parts = $CommandLine -split '\s+', 2
    $command = $parts[0].ToLower()
    $args = if ($parts.Length -gt 1)
    { $parts[1] 
    } else
    { "" 
    }

    switch ($command)
    {
        "help"
        { Show-ShellHelp 
        }
        "exit"
        { Stop-UserShell 
        }
        "quit"
        { Stop-UserShell 
        }
        "clear"
        { Clear-Host 
        }
        "cls"
        { Clear-Host 
        }

        # Commandes utilisateurs
        "user-list"
        { Invoke-UserList 
        }
        "user-show"
        { Invoke-UserShow -UserName $args 
        }
        "user-create"
        { Invoke-UserCreate 
        }
        "user-modify"
        { Invoke-UserModify -UserName $args 
        }
        "user-delete"
        { Invoke-UserDelete -UserName $args 
        }
        "user-enable"
        { Invoke-UserEnable -UserName $args 
        }
        "user-disable"
        { Invoke-UserDisable -UserName $args 
        }
        "user-password"
        { Invoke-UserPassword -UserName $args 
        }

        # Commandes groupes
        "group-list"
        { Invoke-GroupList 
        }
        "group-show"
        { Invoke-GroupShow -GroupName $args 
        }
        "group-create"
        { Invoke-GroupCreate 
        }
        "group-modify"
        { Invoke-GroupModify -GroupName $args 
        }
        "group-delete"
        { Invoke-GroupDelete -GroupName $args 
        }
        "group-addmember"
        { Invoke-GroupAddMember -GroupName $args 
        }
        "group-removemember"
        { Invoke-GroupRemoveMember -GroupName $args 
        }

        default
        {
            Write-LogWarning "Commande inconnue: '$command'. Tapez 'help' pour l'aide."
        }
    }
}

function Show-ShellHelp
{
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Aide - Commandes disponibles" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Write-Host "`nCommandes generales:" -ForegroundColor Yellow
    Write-Host "  help                      - Afficher cette aide"
    Write-Host "  exit, quit                - Quitter le shell"
    Write-Host "  clear, cls                - Effacer l'ecran"

    Write-Host "`nGestion des utilisateurs:" -ForegroundColor Yellow
    Write-Host "  user-list                 - Lister tous les utilisateurs"
    Write-Host "  user-show <nom>           - Afficher les details d'un utilisateur"
    Write-Host "  user-create               - Creer un nouvel utilisateur"
    Write-Host "  user-modify <nom>         - Modifier un utilisateur"
    Write-Host "  user-delete <nom>         - Supprimer un utilisateur"
    Write-Host "  user-enable <nom>         - Activer un utilisateur"
    Write-Host "  user-disable <nom>        - Desactiver un utilisateur"
    Write-Host "  user-password <nom>       - Changer le mot de passe"

    Write-Host "`nGestion des groupes:" -ForegroundColor Yellow
    Write-Host "  group-list                - Lister tous les groupes"
    Write-Host "  group-show <nom>          - Afficher les details d'un groupe"
    Write-Host "  group-create              - Creer un nouveau groupe"
    Write-Host "  group-modify <nom>        - Modifier un groupe"
    Write-Host "  group-delete <nom>        - Supprimer un groupe"
    Write-Host "  group-addmember <groupe>  - Ajouter un membre a un groupe"
    Write-Host "  group-removemember <grp>  - Retirer un membre d'un groupe"

    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

# Fonctions pour les utilisateurs

function Invoke-UserList
{
    $users = Get-AllLocalUsers
    Show-LocalUserList -Users $users
}

function Invoke-UserShow
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur"
    }

    $user = Get-LocalUserInfo -UserName $UserName
    Show-LocalUser -User $user
}

function Invoke-UserCreate
{
    Write-Host "`nCreation d'un nouvel utilisateur" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan

    $userName = Read-Host "Nom d'utilisateur"

    if ([string]::IsNullOrWhiteSpace($userName))
    {
        Write-LogError "Le nom d'utilisateur ne peut pas etre vide"
        return
    }

    $password = Read-Host "Mot de passe" -AsSecureString
    $fullName = Read-Host "Nom complet (optionnel)"
    $description = Read-Host "Description (optionnel)"

    $passwordNeverExpires = Read-Host "Le mot de passe n'expire jamais? (O/N)"
    $userMayNotChangePassword = Read-Host "L'utilisateur ne peut pas changer le mot de passe? (O/N)"

    $properties = @{
        PasswordNeverExpires = ($passwordNeverExpires -eq 'O' -or $passwordNeverExpires -eq 'o')
        UserMayNotChangePassword = ($userMayNotChangePassword -eq 'O' -or $userMayNotChangePassword -eq 'o')
        AccountNeverExpires = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($fullName))
    {
        $properties['FullName'] = $fullName
    }

    if (-not [string]::IsNullOrWhiteSpace($description))
    {
        $properties['Description'] = $description
    }

    New-LocalUserAccount -UserName $userName -Password $password -Properties $properties
}

function Invoke-UserModify
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur a modifier"
    }

    if (-not (Test-LocalUserExists -UserName $UserName))
    {
        Write-LogError "L'utilisateur '$UserName' n'existe pas"
        return
    }

    Write-Host "`nModification de l'utilisateur: $UserName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "(Laissez vide pour ne pas modifier)`n"

    $fullName = Read-Host "Nouveau nom complet"
    $description = Read-Host "Nouvelle description"
    $passwordNeverExpires = Read-Host "Le mot de passe n'expire jamais? (O/N/Vide)"
    $userMayNotChangePassword = Read-Host "L'utilisateur ne peut pas changer le mot de passe? (O/N/Vide)"

    $properties = @{}

    if (-not [string]::IsNullOrWhiteSpace($fullName))
    {
        $properties['FullName'] = $fullName
    }

    if (-not [string]::IsNullOrWhiteSpace($description))
    {
        $properties['Description'] = $description
    }

    if (-not [string]::IsNullOrWhiteSpace($passwordNeverExpires))
    {
        $properties['PasswordNeverExpires'] = ($passwordNeverExpires -eq 'O' -or $passwordNeverExpires -eq 'o')
    }

    if (-not [string]::IsNullOrWhiteSpace($userMayNotChangePassword))
    {
        $properties['UserMayNotChangePassword'] = ($userMayNotChangePassword -eq 'O' -or $userMayNotChangePassword -eq 'o')
    }

    if ($properties.Count -gt 0)
    {
        Update-LocalUserAccount -UserName $UserName -Properties $properties
    } else
    {
        Write-LogWarning "Aucune modification specifiee"
    }
}

function Invoke-UserDelete
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur a supprimer"
    }

    $confirmation = Read-Host "Etes-vous sur de vouloir supprimer l'utilisateur '$UserName'? (O/N)"

    if ($confirmation -eq 'O' -or $confirmation -eq 'o')
    {
        Remove-LocalUserAccount -UserName $UserName
    } else
    {
        Write-LogInfo "Suppression annulee"
    }
}

function Invoke-UserEnable
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur a activer"
    }

    Enable-LocalUserAccount -UserName $UserName
}

function Invoke-UserDisable
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur a desactiver"
    }

    Disable-LocalUserAccount -UserName $UserName
}

function Invoke-UserPassword
{
    param([string]$UserName)

    if ([string]::IsNullOrWhiteSpace($UserName))
    {
        $UserName = Read-Host "Nom de l'utilisateur"
    }

    if (-not (Test-LocalUserExists -UserName $UserName))
    {
        Write-LogError "L'utilisateur '$UserName' n'existe pas"
        return
    }

    $newPassword = Read-Host "Nouveau mot de passe" -AsSecureString
    $confirmPassword = Read-Host "Confirmer le mot de passe" -AsSecureString

    $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
    $pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword))

    if ($pwd1 -ne $pwd2)
    {
        Write-LogError "Les mots de passe ne correspondent pas"
        return
    }

    Set-LocalUserPassword -UserName $UserName -NewPassword $newPassword
}

# Fonctions pour les groupes

function Invoke-GroupList
{
    $groups = Get-AllLocalGroups
    Show-LocalGroupList -Groups $groups
}

function Invoke-GroupShow
{
    param([string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName))
    {
        $GroupName = Read-Host "Nom du groupe"
    }

    $group = Get-LocalGroupInfo -GroupName $GroupName
    Show-LocalGroup -Group $group
}

function Invoke-GroupCreate
{
    Write-Host "`nCreation d'un nouveau groupe" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan

    $groupName = Read-Host "Nom du groupe"

    if ([string]::IsNullOrWhiteSpace($groupName))
    {
        Write-LogError "Le nom du groupe ne peut pas etre vide"
        return
    }

    $description = Read-Host "Description (optionnel)"

    New-LocalGroupAccount -GroupName $groupName -Description $description
}

function Invoke-GroupModify
{
    param([string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName))
    {
        $GroupName = Read-Host "Nom du groupe a modifier"
    }

    if (-not (Test-LocalGroupExists -GroupName $GroupName))
    {
        Write-LogError "Le groupe '$GroupName' n'existe pas"
        return
    }

    Write-Host "`nModification du groupe: $GroupName" -ForegroundColor Cyan
    $description = Read-Host "Nouvelle description"

    if (-not [string]::IsNullOrWhiteSpace($description))
    {
        Update-LocalGroupAccount -GroupName $GroupName -Description $description
    } else
    {
        Write-LogWarning "Aucune modification specifiee"
    }
}

function Invoke-GroupDelete
{
    param([string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName))
    {
        $GroupName = Read-Host "Nom du groupe a supprimer"
    }

    $confirmation = Read-Host "Etes-vous sur de vouloir supprimer le groupe '$GroupName'? (O/N)"

    if ($confirmation -eq 'O' -or $confirmation -eq 'o')
    {
        Remove-LocalGroupAccount -GroupName $GroupName
    } else
    {
        Write-LogInfo "Suppression annulee"
    }
}

function Invoke-GroupAddMember
{
    param([string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName))
    {
        $GroupName = Read-Host "Nom du groupe"
    }

    if (-not (Test-LocalGroupExists -GroupName $GroupName))
    {
        Write-LogError "Le groupe '$GroupName' n'existe pas"
        return
    }

    $memberName = Read-Host "Nom du membre a ajouter"

    if ([string]::IsNullOrWhiteSpace($memberName))
    {
        Write-LogError "Le nom du membre ne peut pas etre vide"
        return
    }

    Add-LocalGroupMemberAccount -GroupName $GroupName -MemberName $memberName
}

function Invoke-GroupRemoveMember
{
    param([string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName))
    {
        $GroupName = Read-Host "Nom du groupe"
    }

    if (-not (Test-LocalGroupExists -GroupName $GroupName))
    {
        Write-LogError "Le groupe '$GroupName' n'existe pas"
        return
    }

    $memberName = Read-Host "Nom du membre a retirer"

    if ([string]::IsNullOrWhiteSpace($memberName))
    {
        Write-LogError "Le nom du membre ne peut pas etre vide"
        return
    }

    Remove-LocalGroupMemberAccount -GroupName $GroupName -MemberName $memberName
}

Export-ModuleMember -Function Start-UserShell, Stop-UserShell
