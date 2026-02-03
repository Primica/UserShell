# Module de gestion des groupes locaux

function Get-AllLocalGroups
{
    try
    {
        $groups = Get-LocalGroup -ErrorAction Stop
        $localGroups = @()

        foreach ($group in $groups)
        {
            $members = @()
            try
            {
                $groupMembers = Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue
                $members = $groupMembers | ForEach-Object { $_.Name }
            } catch
            {
                $members = @()
            }

            $localGroups += [PSCustomObject]@{
                Name = $group.Name
                Description = $group.Description
                SID = $group.SID.Value
                Members = $members
            }
        }

        Write-LogInfo "Retrieved $($localGroups.Count) local groups"
        return $localGroups
    } catch
    {
        Write-LogError "Failed to retrieve groups: $($_.Exception.Message)"
        return @()
    }
}

function Get-LocalGroupInfo
{
    param([string]$GroupName)

    try
    {
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop

        $members = @()
        try
        {
            $groupMembers = Get-LocalGroupMember -Group $GroupName -ErrorAction SilentlyContinue
            $members = $groupMembers | ForEach-Object { $_.Name }
        } catch
        {
            $members = @()
        }

        $localGroup = [PSCustomObject]@{
            Name = $group.Name
            Description = $group.Description
            SID = $group.SID.Value
            Members = $members
        }
        Write-LogInfo "Retrieved group: $GroupName"
        return $localGroup
    } catch
    {
        Write-LogError "Group '$GroupName' not found: $($_.Exception.Message)"
        return $null
    }
}

function New-LocalGroupAccount
{
    param(
        [string]$GroupName,
        [string]$Description
    )

    try
    {
        if (Test-LocalGroupExists -GroupName $GroupName)
        {
            Write-LogWarning "Group '$GroupName' already exists"
            return $false
        }

        $params = @{
            Name = $GroupName
            ErrorAction = 'Stop'
        }

        if ($Description)
        {
            $params['Description'] = $Description
        }

        New-LocalGroup @params | Out-Null
        Write-LogSuccess "Group '$GroupName' created successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to create group '$GroupName': $($_.Exception.Message)"
        return $false
    }
}

function Update-LocalGroupAccount
{
    param(
        [string]$GroupName,
        [string]$Description
    )

    try
    {
        if (-not (Test-LocalGroupExists -GroupName $GroupName))
        {
            Write-LogError "Group '$GroupName' does not exist"
            return $false
        }

        Set-LocalGroup -Name $GroupName -Description $Description -ErrorAction Stop
        Write-LogSuccess "Group '$GroupName' modified successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to modify group '$GroupName': $($_.Exception.Message)"
        return $false
    }
}

function Remove-LocalGroupAccount
{
    param([string]$GroupName)

    try
    {
        if (-not (Test-LocalGroupExists -GroupName $GroupName))
        {
            Write-LogError "Group '$GroupName' does not exist"
            return $false
        }

        Remove-LocalGroup -Name $GroupName -ErrorAction Stop
        Write-LogSuccess "Group '$GroupName' deleted successfully"
        return $true
    } catch
    {
        Write-LogError "Failed to delete group '$GroupName': $($_.Exception.Message)"
        return $false
    }
}

function Add-LocalGroupMemberAccount
{
    param(
        [string]$GroupName,
        [string]$MemberName
    )

    try
    {
        if (-not (Test-LocalGroupExists -GroupName $GroupName))
        {
            Write-LogError "Group '$GroupName' does not exist"
            return $false
        }

        Add-LocalGroupMember -Group $GroupName -Member $MemberName -ErrorAction Stop
        Write-LogSuccess "Added '$MemberName' to group '$GroupName'"
        return $true
    } catch
    {
        Write-LogError "Failed to add member to group: $($_.Exception.Message)"
        return $false
    }
}

function Remove-LocalGroupMemberAccount
{
    param(
        [string]$GroupName,
        [string]$MemberName
    )

    try
    {
        if (-not (Test-LocalGroupExists -GroupName $GroupName))
        {
            Write-LogError "Group '$GroupName' does not exist"
            return $false
        }

        Remove-LocalGroupMember -Group $GroupName -Member $MemberName -ErrorAction Stop
        Write-LogSuccess "Removed '$MemberName' from group '$GroupName'"
        return $true
    } catch
    {
        Write-LogError "Failed to remove member from group: $($_.Exception.Message)"
        return $false
    }
}

function Get-LocalGroupMemberList
{
    param([string]$GroupName)

    try
    {
        $members = Get-LocalGroupMember -Group $GroupName -ErrorAction Stop
        $memberNames = $members | ForEach-Object { $_.Name }
        Write-LogInfo "Group '$GroupName' has $($memberNames.Count) members"
        return $memberNames
    } catch
    {
        Write-LogError "Failed to get members of group '$GroupName': $($_.Exception.Message)"
        return @()
    }
}

function Test-LocalGroupExists
{
    param([string]$GroupName)

    try
    {
        Get-LocalGroup -Name $GroupName -ErrorAction Stop | Out-Null
        return $true
    } catch
    {
        return $false
    }
}

function Show-LocalGroup
{
    param([object]$Group)

    if ($null -eq $Group)
    {
        Write-LogWarning "No group to display"
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Group Information" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Name:                  $($Group.Name)"
    Write-Host "Description:           $($Group.Description)"
    Write-Host "SID:                   $($Group.SID)"
    Write-Host "Member Count:          $($Group.Members.Count)"
    Write-Host "`nMembers:" -ForegroundColor Yellow

    if ($Group.Members.Count -gt 0)
    {
        foreach ($member in $Group.Members)
        {
            Write-Host "  - $member"
        }
    } else
    {
        Write-Host "  (No members)"
    }

    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Show-LocalGroupList
{
    param([array]$Groups)

    if ($Groups.Count -eq 0)
    {
        Write-LogWarning "No groups to display"
        return
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Local Groups ($($Groups.Count))" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $groupData = $Groups | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Description = $_.Description
            Members = $_.Members.Count
            SID = $_.SID
        }
    }

    $groupData | Format-Table -Property Name, Description, Members, SID -AutoSize | Out-Host

    Write-Host "========================================`n" -ForegroundColor Cyan
}

Export-ModuleMember -Function Get-AllLocalGroups, Get-LocalGroupInfo, New-LocalGroupAccount, Update-LocalGroupAccount, Remove-LocalGroupAccount, Add-LocalGroupMemberAccount, Remove-LocalGroupMemberAccount, Get-LocalGroupMemberList, Test-LocalGroupExists, Show-LocalGroup, Show-LocalGroupList
