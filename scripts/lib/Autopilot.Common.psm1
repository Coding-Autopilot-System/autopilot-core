function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
  $line = "[$timestamp] [$Level] $Message"
  Write-Output $line
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
  if (-not (Get-Item -Path ("Env:" + $Name) -ErrorAction SilentlyContinue)) {
    throw "Missing required env var: $Name"
  }
}

function Invoke-Gh {
  param([string[]]$Arguments)
  $cmd = @("gh") + $Arguments
  Write-Log "Running: $($cmd -join ' ')"
  & $cmd
  if ($LASTEXITCODE -ne 0) {
    throw "gh failed with exit code $LASTEXITCODE"
  }
}

function Invoke-GhJson {
  param([string[]]$Arguments)
  $json = gh @Arguments 2>$null
  if (-not $json) { return $null }
  $trimmed = $json.Trim()
  $objIndex = $trimmed.IndexOf('{')
  $arrIndex = $trimmed.IndexOf('[')
  $start = @($objIndex, $arrIndex) | Where-Object { $_ -ge 0 } | Sort-Object | Select-Object -First 1
  if ($start -gt 0) {
    $trimmed = $trimmed.Substring($start)
  }
  return $trimmed | ConvertFrom-Json
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
  param([string]$Command, [string[]]$Arguments = @())
  Write-Log "Running: $Command $($Arguments -join ' ')"
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command (exit $LASTEXITCODE)"
  }
}

function Invoke-CheckedLogged {
  param([string]$Command, [string[]]$Arguments = @(), [string]$LogPath)
  Write-Log "Running: $Command $($Arguments -join ' ')"
  if ($LogPath) {
    & $Command @Arguments 2>&1 | Tee-Object -FilePath $LogPath -Append
  } else {
    & $Command @Arguments
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command (exit $LASTEXITCODE)"
  }
}

function Get-LogTail {
  param([string]$LogPath, [int]$Lines = 40)
  if (-not (Test-Path $LogPath)) { return $null }
  return Get-Content $LogPath -Tail $Lines
}

Export-ModuleMember -Function Write-Log, Initialize-Log, Assert-Env, Invoke-Gh, Invoke-GhJson, Get-RepoName, Test-Tool, Invoke-Checked, Invoke-CheckedLogged, Get-LogTail
