function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
  $line = "[$timestamp] [$Level] $Message"
  Write-Host $line
  if ($script:LogFile) {
    Add-Content -Path $script:LogFile -Value $line
  }
}

function Initialize-Log {
  $logDir = Join-Path $env:TEMP "autopilot\logs"
  New-Item -ItemType Directory -Force $logDir | Out-Null
  $date = (Get-Date).ToString("yyyyMMdd")
  $script:LogFile = Join-Path $logDir "operator_$date.log"
  Write-Log "Log initialized at $script:LogFile"
}

function Assert-Env {
  param([string]$Name)
  if (-not $env:$Name) {
    throw "Missing required env var: $Name"
  }
}

function Invoke-Gh {
  param([string[]]$Args)
  $cmd = @("gh") + $Args
  Write-Log "Running: $($cmd -join ' ')"
  & $cmd
  if ($LASTEXITCODE -ne 0) {
    throw "gh failed with exit code $LASTEXITCODE"
  }
}

function Invoke-GhJson {
  param([string[]]$Args)
  $json = gh @Args
  if (-not $json) { return $null }
  return $json | ConvertFrom-Json
}

function Get-RepoName {
  param([string]$RepoUrl)
  $parts = $RepoUrl.TrimEnd('/') -split '/'
  return "$($parts[-2])/$($parts[-1])"
}

function Test-Tool {
  param([string]$Name)
  $tool = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $tool) {
    throw "Required tool not found: $Name"
  }
}

function Invoke-Checked {
  param([string]$Command, [string[]]$Args = @())
  Write-Log "Running: $Command $($Args -join ' ')"
  & $Command @Args
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command (exit $LASTEXITCODE)"
  }
}

Export-ModuleMember -Function Write-Log, Initialize-Log, Assert-Env, Invoke-Gh, Invoke-GhJson, Get-RepoName, Test-Tool, Invoke-Checked
