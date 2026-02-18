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

            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#'))
            {
                continue
            }

            if ($line -match '^\[\[(\w+)\]\]$')
            {
                if ($null -ne $currentObject -and $null -ne $currentSection)
                {
                    $result[$currentSection] += $currentObject
                }

                $currentSection = $Matches[1]
                $currentObject = @{}
                continue
            }

            if ($line -match '^(\w+)\s*=\s*(.+)$')
            {
                $key = $Matches[1].Trim()
                $value = $Matches[2].Trim()

                if ($value -match '^"(.+)"$')
                {
                    $currentObject[$key] = $Matches[1]
                } elseif ($value -match '^\[(.+)\]$')
                {
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
                    $currentObject[$key] = $value -eq 'true'
                } else
                {
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
