function Share-Path {
    <#
    .SYNOPSIS
    Applique des permissions NTFS (ACL) à un ou plusieurs chemins pour un ou plusieurs utilisateurs/groupes.

    .DESCRIPTION
    `Share-Path` ajoute des règles d'accès NTFS pour des comptes locaux ou de domaine.
    Par défaut, les règles sont appliquées au dossier racine et peuvent être propagées
    récursivement aux sous-dossiers et fichiers avec `-Recursive`.

    .PARAMETER Path
    Chemin(s) du fichier ou dossier à modifier.

    .PARAMETER Identity
    Nom(s) d'utilisateur ou de groupe (par ex. 'DOMAIN\\User' ou 'Administrateurs').

    .PARAMETER Access
    Niveau d'accès: Read, Modify ou FullControl.

    .PARAMETER Recursive
    Si présent, applique les permissions récursivement aux sous-éléments.

    .EXAMPLE
    Share-Path -Path 'C:\Data\Projet' -Identity 'DOMAIN\\Equipe' -Access Modify -Recursive
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string[]]$Path,

        [Parameter(Mandatory=$true, Position=1)]
        [string[]]$Identity,

        [ValidateSet('Read','Modify','FullControl')]
        [string]$Access = 'Read',

        [switch]$Recursive
    )

    begin {
        $rightsMap = @{ 
            'Read' = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute;
            'Modify' = [System.Security.AccessControl.FileSystemRights]::Modify;
            'FullControl' = [System.Security.AccessControl.FileSystemRights]::FullControl
        }
        $rights = $rightsMap[$Access]
        $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None
    }

    process {
        foreach ($p in $Path) {
            try {
                if (-not (Test-Path -LiteralPath $p)) {
                    Write-LogError "Chemin introuvable: $p"
                    continue
                }

                foreach ($id in $Identity) {
                    try {
                        $ntAccount = New-Object System.Security.Principal.NTAccount($id)
                    } catch {
                        Write-LogError "Identité invalide ou non résolue: $id"
                        continue
                    }

                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                        $ntAccount,
                        $rights,
                        $inheritanceFlags,
                        $propagationFlags,
                        [System.Security.AccessControl.AccessControlType]::Allow
                    )

                    try {
                        $acl = Get-Acl -LiteralPath $p
                        $acl.SetAccessRule($rule)
                        Set-Acl -LiteralPath $p -AclObject $acl
                        Write-LogSuccess "Règle ajoutée: $id -> $p ($Access)"
                    } catch {
                        Write-LogError "Échec Set-Acl pour $p : $($_.Exception.Message)"
                        continue
                    }

                    if ($Recursive) {
                        try {
                            Get-ChildItem -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                                try {
                                    $childAcl = Get-Acl -LiteralPath $_.FullName
                                    $childAcl.SetAccessRule($rule)
                                    Set-Acl -LiteralPath $_.FullName -AclObject $childAcl
                                } catch {
                                    Write-LogWarning "Impossible d'appliquer la règle à $($_.FullName): $($_.Exception.Message)"
                                }
                            }
                        } catch {
                            Write-LogWarning "Erreur lors de l'énumération récursive de ${p}: $($_.Exception.Message)"
                        }
                    }
                }
            } catch {
                Write-LogError "Erreur lors du traitement de $p : $($_.Exception.Message)"
            }
        }
    }
}

Export-ModuleMember -Function Share-Path

function New-NetworkShare {
    <#
    .SYNOPSIS
    Crée un partage SMB pour un dossier et applique des permissions SMB.

    .PARAMETER Path
    Chemin du dossier à partager.

    .PARAMETER ShareName
    Nom du partage. Si vide, le nom du dossier sera utilisé.

    .PARAMETER Identities
    Utilisateurs ou groupes à qui appliquer les permissions SMB.

    .PARAMETER Access
    Niveau d'accès SMB: Read, Change, Full
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]$Path,
        [string]$ShareName,
        [string[]]$Identities = @(),
        [ValidateSet('Read','Change','Full')]
        [string]$Access = 'Read'
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-LogError "Chemin introuvable: $Path"
        return $false
    }

    $smbCmd = Get-Command New-SmbShare -ErrorAction SilentlyContinue
    if ($null -eq $smbCmd) {
        Write-LogError "Cmdlet New-SmbShare introuvable. Le module SMBShare n'est pas disponible"
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($ShareName)) {
        $ShareName = [System.IO.Path]::GetFileName($Path).Replace(' ', '_')
        if ([string]::IsNullOrWhiteSpace($ShareName)) { $ShareName = "share_$([guid]::NewGuid().ToString().Substring(0,8))" }
    }

    try {
        $existing = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-LogWarning "Le partage SMB '$ShareName' existe deja. Mise a jour des permissions"
        } else {
            New-SmbShare -Name $ShareName -Path $Path -FolderEnumerationMode AccessBased -ErrorAction Stop | Out-Null
            Write-LogSuccess "Partage SMB créé: $ShareName -> $Path"
        }

        if ($Identities.Count -gt 0) {
            foreach ($id in $Identities) {
                try {
                    $right = switch ($Access) { 'Read' { 'Read' } 'Change' { 'Change' } 'Full' { 'Full' } }
                    Grant-SmbShareAccess -Name $ShareName -AccountName $id -AccessRight $right -Force -ErrorAction Stop | Out-Null
                    Write-LogSuccess "Permission SMB accordee: $id -> $ShareName ($right)"
                } catch {
                    Write-LogError "Impossible d'accorder la permission SMB a ${id}: $($_.Exception.Message)"
                }
            }
        }

        return $true
    } catch {
        Write-LogError "Erreur New-NetworkShare: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Share-Path, New-NetworkShare
