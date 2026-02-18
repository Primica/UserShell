# Module d'exécution de scripts TOML pour UserShell

function Invoke-TomlScript
{
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath))
    {
        Write-LogError "Le fichier script '$FilePath' n'existe pas"
        return $false
    }

    Write-LogInfo "Exécution du script: $FilePath"

    $script = ConvertFrom-Toml -FilePath $FilePath

    if ($null -eq $script)
    {
        Write-LogError "Impossible de parser le fichier TOML"
        return $false
    }

    $successCount = 0
    $errorCount = 0

    if ($script.ContainsKey('users') -and $script.users.Count -gt 0)
    {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Traitement des utilisateurs" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan

        foreach ($userConfig in $script.users)
        {
            $result = Invoke-UserOperation -UserConfig $userConfig
            if ($result)
            {
                $successCount++
            } else
            {
                $errorCount++
            }
        }
    }

    if ($script.ContainsKey('groups') -and $script.groups.Count -gt 0)
    {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Traitement des groupes" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan

        foreach ($groupConfig in $script.groups)
        {
            $result = Invoke-GroupOperation -GroupConfig $groupConfig
            if ($result)
            {
                $successCount++
            } else
            {
                $errorCount++
            }
        }
    }

    if ($script.ContainsKey('shares') -and $script.shares.Count -gt 0)
    {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Traitement des partages (shares)" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan

        foreach ($shareConfig in $script.shares)
        {
            $result = Invoke-ShareFromConfig -ShareConfig $shareConfig
            if ($result)
            {
                $successCount++
            } else
            {
                $errorCount++
            }
        }
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Rapport d'exécution" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Opérations réussies: $successCount" -ForegroundColor Green
    Write-Host "Opérations échouées: $errorCount" -ForegroundColor $(if ($errorCount -eq 0)
        { "Green" 
        } else
        { "Red" 
        })
    Write-Host "Total: $($successCount + $errorCount)" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-LogInfo "Script terminé: $successCount réussi(es), $errorCount échoué(es)"

    return $errorCount -eq 0
}

function Invoke-UserOperation
{
    param(
        [hashtable]$UserConfig
    )

    if (-not $UserConfig.ContainsKey('name'))
    {
        Write-LogError "Configuration utilisateur invalide: 'name' est requis"
        return $false
    }

    $userName = $UserConfig['name']
    $action = if ($UserConfig.ContainsKey('action'))
    { $UserConfig['action'] 
    } else
    { 'create' 
    }

    Write-Host "`nUtilisateur: $userName (action: $action)" -ForegroundColor Yellow

    switch ($action.ToLower())
    {
        'create'
        {
            return Invoke-UserCreateFromConfig -UserConfig $UserConfig
        }
        'modify'
        {
            return Invoke-UserModifyFromConfig -UserConfig $UserConfig
        }
        'delete'
        {
            return Remove-LocalUserAccount -UserName $userName
        }
        'enable'
        {
            return Enable-LocalUserAccount -UserName $userName
        }
        'disable'
        {
            return Disable-LocalUserAccount -UserName $userName
        }
        default
        {
            Write-LogError "Action '$action' inconnue pour l'utilisateur. Actions valides: create, modify, delete, enable, disable"
            return $false
        }
    }
}

function Invoke-UserCreateFromConfig
{
    param(
        [hashtable]$UserConfig
    )

    $userName = $UserConfig['name']

    if (Test-LocalUserExists -UserName $userName)
    {
        Write-LogWarning "L'utilisateur '$userName' existe déjà, ignoré"
        return $true
    }

    $password = $null
    if ($UserConfig.ContainsKey('password'))
    {
        $password = ConvertTo-SecureString $UserConfig['password'] -AsPlainText -Force
    } else
    {
        $randomPassword = -join ((65..90) + (97..122) + (48..57) + (33, 35, 36, 37, 38, 42) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
        $password = ConvertTo-SecureString $randomPassword -AsPlainText -Force
        Write-LogWarning "Mot de passe généré automatiquement pour '$userName'"
    }

    $properties = @{
        AccountNeverExpires = $true
    }

    if ($UserConfig.ContainsKey('fullname'))
    {
        $properties['FullName'] = $UserConfig['fullname']
    }

    if ($UserConfig.ContainsKey('description'))
    {
        $properties['Description'] = $UserConfig['description']
    }

    if ($UserConfig.ContainsKey('password_never_expires'))
    {
        $properties['PasswordNeverExpires'] = $UserConfig['password_never_expires']
    }

    if ($UserConfig.ContainsKey('cannot_change_password'))
    {
        $properties['UserMayNotChangePassword'] = $UserConfig['cannot_change_password']
    }

    $result = New-LocalUserAccount -UserName $userName -Password $password -Properties $properties

    if ($result -and $UserConfig.ContainsKey('groups'))
    {
        foreach ($groupName in $UserConfig['groups'])
        {
            if (Test-LocalGroupExists -GroupName $groupName)
            {
                Add-LocalGroupMemberAccount -GroupName $groupName -MemberName $userName | Out-Null
            } else
            {
                Write-LogWarning "Le groupe '$groupName' n'existe pas, utilisateur non ajouté"
            }
        }
    }

    return $result
}

function Invoke-UserModifyFromConfig
{
    param(
        [hashtable]$UserConfig
    )

    $userName = $UserConfig['name']

    if (-not (Test-LocalUserExists -UserName $userName))
    {
        Write-LogError "L'utilisateur '$userName' n'existe pas"
        return $false
    }

    $properties = @{}

    if ($UserConfig.ContainsKey('fullname'))
    {
        $properties['FullName'] = $UserConfig['fullname']
    }

    if ($UserConfig.ContainsKey('description'))
    {
        $properties['Description'] = $UserConfig['description']
    }

    if ($UserConfig.ContainsKey('password_never_expires'))
    {
        $properties['PasswordNeverExpires'] = $UserConfig['password_never_expires']
    }

    if ($UserConfig.ContainsKey('cannot_change_password'))
    {
        $properties['UserMayNotChangePassword'] = $UserConfig['cannot_change_password']
    }

    if ($properties.Count -eq 0)
    {
        Write-LogWarning "Aucune propriété à modifier pour '$userName'"
        return $true
    }

    $result = Update-LocalUserAccount -UserName $userName -Properties $properties

    if ($result -and $UserConfig.ContainsKey('password'))
    {
        $password = ConvertTo-SecureString $UserConfig['password'] -AsPlainText -Force
        $result = Set-LocalUserPassword -UserName $userName -NewPassword $password
    }

    if ($result -and $UserConfig.ContainsKey('groups'))
    {
        foreach ($groupName in $UserConfig['groups'])
        {
            if (Test-LocalGroupExists -GroupName $groupName)
            {
                try
                {
                    Add-LocalGroupMemberAccount -GroupName $groupName -MemberName $userName | Out-Null
                } catch
                {
                    Write-LogWarning "L'utilisateur '$userName' est déjà membre du groupe '$groupName'"
                }
            }
        }
    }

    return $result
}

function Invoke-GroupOperation
{
    param(
        [hashtable]$GroupConfig
    )

    if (-not $GroupConfig.ContainsKey('name'))
    {
        Write-LogError "Configuration groupe invalide: 'name' est requis"
        return $false
    }

    $groupName = $GroupConfig['name']
    $action = if ($GroupConfig.ContainsKey('action'))
    { $GroupConfig['action'] 
    } else
    { 'create' 
    }

    Write-Host "`nGroupe: $groupName (action: $action)" -ForegroundColor Yellow

    switch ($action.ToLower())
    {
        'create'
        {
            return Invoke-GroupCreateFromConfig -GroupConfig $GroupConfig
        }
        'modify'
        {
            return Invoke-GroupModifyFromConfig -GroupConfig $GroupConfig
        }
        'delete'
        {
            return Remove-LocalGroupAccount -GroupName $groupName
        }
        'add_members'
        {
            return Invoke-GroupAddMembersFromConfig -GroupConfig $GroupConfig
        }
        'remove_members'
        {
            return Invoke-GroupRemoveMembersFromConfig -GroupConfig $GroupConfig
        }
        default
        {
            Write-LogError "Action '$action' inconnue pour le groupe. Actions valides: create, modify, delete, add_members, remove_members"
            return $false
        }
    }
}

function Invoke-GroupCreateFromConfig
{
    param(
        [hashtable]$GroupConfig
    )

    $groupName = $GroupConfig['name']

    if (Test-LocalGroupExists -GroupName $groupName)
    {
        Write-LogWarning "Le groupe '$groupName' existe déjà, ignoré"
        return $true
    }

    $description = if ($GroupConfig.ContainsKey('description'))
    { $GroupConfig['description'] 
    } else
    { "" 
    }

    $result = New-LocalGroupAccount -GroupName $groupName -Description $description

    if ($result -and $GroupConfig.ContainsKey('members'))
    {
        foreach ($memberName in $GroupConfig['members'])
        {
            Add-LocalGroupMemberAccount -GroupName $groupName -MemberName $memberName | Out-Null
        }
    }

    return $result
}

function Invoke-GroupModifyFromConfig
{
    param(
        [hashtable]$GroupConfig
    )

    $groupName = $GroupConfig['name']

    if (-not (Test-LocalGroupExists -GroupName $groupName))
    {
        Write-LogError "Le groupe '$groupName' n'existe pas"
        return $false
    }

    if (-not $GroupConfig.ContainsKey('description'))
    {
        Write-LogWarning "Aucune description à modifier pour le groupe '$groupName'"
        return $true
    }

    return Update-LocalGroupAccount -GroupName $groupName -Description $GroupConfig['description']
}

function Invoke-GroupAddMembersFromConfig
{
    param(
        [hashtable]$GroupConfig
    )

    $groupName = $GroupConfig['name']

    if (-not (Test-LocalGroupExists -GroupName $groupName))
    {
        Write-LogError "Le groupe '$groupName' n'existe pas"
        return $false
    }

    if (-not $GroupConfig.ContainsKey('members'))
    {
        Write-LogWarning "Aucun membre à ajouter au groupe '$groupName'"
        return $true
    }

    $success = $true
    foreach ($memberName in $GroupConfig['members'])
    {
        $result = Add-LocalGroupMemberAccount -GroupName $groupName -MemberName $memberName
        if (-not $result)
        {
            $success = $false
        }
    }

    return $success
}

function Invoke-GroupRemoveMembersFromConfig
{
    param(
        [hashtable]$GroupConfig
    )

    $groupName = $GroupConfig['name']

    if (-not (Test-LocalGroupExists -GroupName $groupName))
    {
        Write-LogError "Le groupe '$groupName' n'existe pas"
        return $false
    }

    if (-not $GroupConfig.ContainsKey('members'))
    {
        Write-LogWarning "Aucun membre à retirer du groupe '$groupName'"
        return $true
    }

    $success = $true
    foreach ($memberName in $GroupConfig['members'])
    {
        $result = Remove-LocalGroupMemberAccount -GroupName $groupName -MemberName $memberName
        if (-not $result)
        {
            $success = $false
        }
    }

    return $success
}

Export-ModuleMember -Function Invoke-TomlScript, Invoke-ShareFromConfig, Invoke-ShareOperation

function Invoke-ShareFromConfig
{
    param(
        [hashtable]$ShareConfig
    )

    if (-not $ShareConfig.ContainsKey('paths'))
    {
        Write-LogError "Configuration share invalide: 'paths' est requis"
        return $false
    }

    $paths = @($ShareConfig['paths']) -replace '^"|"$',''

    $identities = @()
    if ($ShareConfig.ContainsKey('identities')) { $identities = @($ShareConfig['identities']) }

    $access = if ($ShareConfig.ContainsKey('access')) { $ShareConfig['access'] } else { 'Read' }
    $recursive = if ($ShareConfig.ContainsKey('recursive')) { [bool]$ShareConfig['recursive'] } else { $false }

    $smb = if ($ShareConfig.ContainsKey('smb')) { [bool]$ShareConfig['smb'] } else { $false }
    $shareName = if ($ShareConfig.ContainsKey('share_name')) { $ShareConfig['share_name'] } else { $null }

    $allOk = $true
    foreach ($p in $paths) {
        $resAcl = $false
        try {
            $resAcl = Share-Path -Path $p -Identity $identities -Access $access -Recursive:($recursive)
        } catch {
            Write-LogError "Échec ACL pour $p: $($_.Exception.Message)"
            $resAcl = $false
        }

        if (-not $resAcl) { $allOk = $false }

        if ($smb) {
            try {
                $nameToUse = $shareName
                if ($paths.Count -gt 1 -and -not $nameToUse) { $nameToUse = ([System.IO.Path]::GetFileName($p)).Replace(' ', '_') }
                New-NetworkShare -Path $p -ShareName $nameToUse -Identities $identities -Access (if ($access -eq 'Modify') { 'Change' } elseif ($access -eq 'FullControl') { 'Full' } else { 'Read' }) | Out-Null
            } catch {
                Write-LogError "Échec SMB pour $p: $($_.Exception.Message)"
                $allOk = $false
            }
        }
    }

    return $allOk
}

function Invoke-ShareOperation
{
    param(
        [string[]]$Paths,
        [string[]]$Identities,
        [string]$Access = 'Read',
        [switch]$Recursive
    )

    try {
        Share-Path -Path $Paths -Identity $Identities -Access $Access -Recursive:($Recursive.IsPresent)
        return $true
    } catch {
        Write-LogError "Erreur Invoke-ShareOperation: $($_.Exception.Message)"
        return $false
    }
}
