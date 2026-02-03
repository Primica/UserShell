# Module de gestion des utilisateurs locaux

function Get-AllLocalUsers
{
    try
    {
        $users = Get-LocalUser -ErrorAction Stop
        $localUsers = @()

        foreach ($user in $users)
        {
            $localUsers += [PSCustomObject]@{
                Name = $user.Name
                FullName = $user.FullName
                Description = $user.Description
                Enabled = $user.Enabled
                PasswordRequired = $user.PasswordRequired
                PasswordChangeable = $user.PasswordChangeableDate -ne $null
                PasswordExpires = $user.PasswordExpires
                LastLogon = $user.LastLogon
                SID = $user.SID.Value
            }
        }

        Write-LogInfo "Retrieved $($localUsers.Count) local users"
        return $localUsers
    } catch
    {
        Write-LogError "Failed to retrieve users: $($_.Exception.Message)"
        return @()
    }
}

function Get-LocalUserInfo
{
    param([string]$UserName)

    try
    {
        $user = Get-LocalUser -Name $UserName -ErrorAction Stop
        $localUser = [PSCustomObject]@{
            Name = $user.Name
            FullName = $user.FullName
            Description = $user.Description
            Enabled = $user.Enabled
            PasswordRequired = $user.PasswordRequired
            PasswordChangeable = $user.PasswordChangeableDate -ne $null
            PasswordExpires = $user.PasswordExpires
            LastLogon = $user.LastLogon
            SID = $user.SID.Value
        }
        Write-LogInfo "Retrieved user: $UserName"
        return $localUser
    } catch
    {
        Write-LogError "User '$UserName' not found: $($_.Exception.Message)"
        return $null
    }
}

function New-LocalUserAccount
{
    param(
        [string]$UserName,
        [securestring]$Password,
        [hashtable]$Properties
    )

    try
    {
        if (Test-LocalUserExists -UserName $UserName)
        {
            Write-LogWarning "User '$UserName' already exists"
            return $false
        }

        $params = @{
            Name = $UserName
            Password = $Password
            ErrorAction = 'Stop'
        }

        if ($Properties.ContainsKey('FullName') -and $Properties.FullName)
        {
            $params['FullName'] = $Properties.FullName
        }

        if ($Properties.ContainsKey('Description') -and $Properties.Description)
        {
            $params['Description'] = $Properties.Description
        }

        if ($Properties.ContainsKey('PasswordNeverExpires'))
        {
            $params['PasswordNeverExpires'] = $Properties.PasswordNeverExpires
        }

        if ($Properties.ContainsKey('UserMayNotChangePassword'))
        {
            $params['UserMayNotChangePassword'] = $Properties.UserMayNotChangePassword
        }

        if ($Properties.ContainsKey('AccountNeverExpires'))
        {
            $params['AccountNeverExpires'] = $Properties.AccountNeverExpires
        }

        New-LocalUser @params | Out-Null
        Write-LogSuccess "User '$UserName' created successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to create user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Update-LocalUserAccount
{
    param(
        [string]$UserName,
        [hashtable]$Properties
    )

    try
    {
        if (-not (Test-LocalUserExists -UserName $UserName))
        {
            Write-LogError "User '$UserName' does not exist"
            return $false
        }

        $params = @{
            Name = $UserName
            ErrorAction = 'Stop'
        }

        if ($Properties.ContainsKey('FullName'))
        {
            $params['FullName'] = $Properties.FullName
        }

        if ($Properties.ContainsKey('Description'))
        {
            $params['Description'] = $Properties.Description
        }

        if ($Properties.ContainsKey('PasswordNeverExpires'))
        {
            $params['PasswordNeverExpires'] = $Properties.PasswordNeverExpires
        }

        if ($Properties.ContainsKey('UserMayNotChangePassword'))
        {
            $params['UserMayNotChangePassword'] = $Properties.UserMayNotChangePassword
        }

        if ($Properties.ContainsKey('AccountNeverExpires'))
        {
            $params['AccountNeverExpires'] = $Properties.AccountNeverExpires
        }

        Set-LocalUser @params
        Write-LogSuccess "User '$UserName' modified successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to modify user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Remove-LocalUserAccount
{
    param([string]$UserName)

    try
    {
        if (-not (Test-LocalUserExists -UserName $UserName))
        {
            Write-LogError "User '$UserName' does not exist"
            return $false
        }

        Remove-LocalUser -Name $UserName -ErrorAction Stop
        Write-LogSuccess "User '$UserName' deleted successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to delete user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Enable-LocalUserAccount
{
    param([string]$UserName)

    try
    {
        Enable-LocalUser -Name $UserName -ErrorAction Stop
        Write-LogSuccess "User '$UserName' enabled"
        return $true
    } catch
    {
        Write-LogError "Failed to enable user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Disable-LocalUserAccount
{
    param([string]$UserName)

    try
    {
        Disable-LocalUser -Name $UserName -ErrorAction Stop
        Write-LogSuccess "User '$UserName' disabled"
        return $true
    } catch
    {
        Write-LogError "Failed to disable user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Set-LocalUserPassword
{
    param(
        [string]$UserName,
        [securestring]$NewPassword
    )

    try
    {
        Set-LocalUser -Name $UserName -Password $NewPassword -ErrorAction Stop
        Write-LogSuccess "Password changed for user '$UserName'"
        return $true
    } catch
    {
        Write-LogError "Failed to change password for user '$UserName': $($_.Exception.Message)"
        return $false
    }
}

function Test-LocalUserExists
{
    param([string]$UserName)

    try
    {
        Get-LocalUser -Name $UserName -ErrorAction Stop | Out-Null
        return $true
    } catch
    {
        return $false
    }
}

function Show-LocalUser
{
    param([object]$User)

    if ($null -eq $User)
    {
        Write-LogWarning "No user to display"
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "User Information" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Name:                  $($User.Name)"
    Write-Host "Full Name:             $($User.FullName)"
    Write-Host "Description:           $($User.Description)"
    Write-Host "SID:                   $($User.SID)"
    Write-Host "Enabled:               $($User.Enabled)"
    Write-Host "Password Required:     $($User.PasswordRequired)"
    Write-Host "Password Changeable:   $($User.PasswordChangeable)"
    Write-Host "Password Expires:      $($User.PasswordExpires)"
    Write-Host "Last Logon:            $($User.LastLogon)"
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Show-LocalUserList
{
    param([array]$Users)

    if ($Users.Count -eq 0)
    {
        Write-LogWarning "No users to display"
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Local Users ($($Users.Count))" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $Users | Format-Table -Property Name, FullName, Enabled, SID -AutoSize | Out-Host

    Write-Host "========================================`n" -ForegroundColor Cyan
}

Export-ModuleMember -Function Get-AllLocalUsers, Get-LocalUserInfo, New-LocalUserAccount, Update-LocalUserAccount, Remove-LocalUserAccount, Enable-LocalUserAccount, Disable-LocalUserAccount, Set-LocalUserPassword, Test-LocalUserExists, Show-LocalUser, Show-LocalUserList
