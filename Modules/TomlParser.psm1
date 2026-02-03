# Module de parsing TOML simplifié pour UserShell

function ConvertFrom-Toml
{
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath))
    {
        Write-LogError "Le fichier '$FilePath' n'existe pas"
        return $null
    }

    try
    {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $result = @{
            users = @()
            groups = @()
        }

        $currentSection = $null
        $currentObject = $null

        foreach ($line in ($content -split "`n"))
        {
            $line = $line.Trim()

            # Ignorer les lignes vides et commentaires
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#'))
            {
                continue
            }

            # Détecter les sections [[users]] ou [[groups]]
            if ($line -match '^\[\[(\w+)\]\]$')
            {
                # Sauvegarder l'objet précédent si existant
                if ($null -ne $currentObject -and $null -ne $currentSection)
                {
                    $result[$currentSection] += $currentObject
                }

                $currentSection = $Matches[1]
                $currentObject = @{}
                continue
            }

            # Détecter les clés-valeurs
            if ($line -match '^(\w+)\s*=\s*(.+)$')
            {
                $key = $Matches[1].Trim()
                $value = $Matches[2].Trim()

                # Gérer les différents types de valeurs
                if ($value -match '^"(.+)"$')
                {
                    # String entre guillemets
                    $currentObject[$key] = $Matches[1]
                } elseif ($value -match '^\[(.+)\]$')
                {
                    # Array
                    $arrayContent = $Matches[1]
                    $currentObject[$key] = @($arrayContent -split ',' | ForEach-Object {
                            $item = $_.Trim()
                            if ($item -match '^"(.+)"$')
                            {
                                $Matches[1]
                            } else
                            {
                                $item
                            }
                        })
                } elseif ($value -eq 'true' -or $value -eq 'false')
                {
                    # Boolean
                    $currentObject[$key] = $value -eq 'true'
                } else
                {
                    # Nombre ou string sans guillemets
                    if ($value -match '^\d+$')
                    {
                        $currentObject[$key] = [int]$value
                    } else
                    {
                        $currentObject[$key] = $value
                    }
                }
            }
        }

        # Sauvegarder le dernier objet
        if ($null -ne $currentObject -and $null -ne $currentSection)
        {
            $result[$currentSection] += $currentObject
        }

        Write-LogInfo "Fichier TOML parsé avec succès: $($result.users.Count) utilisateurs, $($result.groups.Count) groupes"
        return $result

    } catch
    {
        Write-LogError "Erreur lors du parsing du fichier TOML: $($_.Exception.Message)"
        return $null
    }
}

function Test-TomlFile
{
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath))
    {
        Write-LogError "Le fichier '$FilePath' n'existe pas"
        return $false
    }

    $extension = [System.IO.Path]::GetExtension($FilePath)
    if ($extension -ne '.toml')
    {
        Write-LogError "Le fichier doit avoir l'extension .toml"
        return $false
    }

    try
    {
        $parsed = ConvertFrom-Toml -FilePath $FilePath
        if ($null -eq $parsed)
        {
            return $false
        }

        # Validation basique de la structure
        if (-not $parsed.ContainsKey('users') -and -not $parsed.ContainsKey('groups'))
        {
            Write-LogError "Le fichier TOML doit contenir au moins une section [[users]] ou [[groups]]"
            return $false
        }

        return $true
    } catch
    {
        Write-LogError "Le fichier TOML n'est pas valide: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function ConvertFrom-Toml, Test-TomlFile
