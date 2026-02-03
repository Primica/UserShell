# Variables du module
$script:LogPath = ""
$script:LogLevel = "INFO"

function Initialize-Logger
{
    param(
        [string]$LogFilePath
    )

    $script:LogPath = $LogFilePath

    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path $logDir))
    {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
}

function Write-Log
{
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    if ($script:LogPath)
    {
        Add-Content -Path $script:LogPath -Value $logEntry
    }

    switch ($Level)
    {
        "ERROR"
        {
            Write-Host $logEntry -ForegroundColor Red
        }
        "WARNING"
        {
            Write-Host $logEntry -ForegroundColor Yellow
        }
        "SUCCESS"
        {
            Write-Host $logEntry -ForegroundColor Green
        }
        default
        {
            Write-Host $logEntry
        }
    }
}

function Write-LogInfo
{
    param([string]$Message)
    Write-Log -Message $Message -Level "INFO"
}

function Write-LogSuccess
{
    param([string]$Message)
    Write-Log -Message $Message -Level "SUCCESS"
}

function Write-LogWarning
{
    param([string]$Message)
    Write-Log -Message $Message -Level "WARNING"
}

function Write-LogError
{
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
}

function Write-LogDebug
{
    param([string]$Message)
    if ($script:LogLevel -eq "DEBUG")
    {
        Write-Log -Message $Message -Level "DEBUG"
    }
}

function Clear-Log
{
    if (Test-Path $script:LogPath)
    {
        Clear-Content -Path $script:LogPath
        Write-LogInfo "Log file cleared"
    }
}

function Set-LogLevel
{
    param([string]$Level)
    $script:LogLevel = $Level
}

Export-ModuleMember -Function Initialize-Logger, Write-Log, Write-LogInfo, Write-LogSuccess, Write-LogWarning, Write-LogError, Write-LogDebug, Clear-Log, Set-LogLevel
