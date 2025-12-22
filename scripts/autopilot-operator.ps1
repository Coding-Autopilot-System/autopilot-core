param()

$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\lib\Autopilot.Common.psm1"
Initialize-Log

Assert-Env -Name "ORG"
$org = $env:ORG

$maxIssues = [int]($env:MAX_ISSUES ?? 5)
$dryRun = ($env:DRY_RUN ?? "false") -eq "true"
$allowlist = @()
if ($env:REPO_ALLOWLIST) {
  $allowlist = $env:REPO_ALLOWLIST.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

Test-Tool -Name "gh"
Test-Tool -Name "git"
Test-Tool -Name "codex"

Write-Log "Autopilot operator starting for org: $org"
Write-Log "Max issues: $maxIssues Dry run: $dryRun"

$query = "org:$org is:issue label:autofix label:queued -label:blocked -label:risky -label:needs-design"
$result = Invoke-GhJson -Args @("api", "search/issues", "-f", "q=$query", "-f", "per_page=$maxIssues")
$issues = $result.items
if (-not $issues -or $issues.Count -eq 0) {
  Write-Log "No issues found."
  exit 0
}

foreach ($issue in $issues) {
  $repo = Get-RepoName -RepoUrl $issue.repository_url
  if ($allowlist.Count -gt 0 -and ($allowlist -notcontains $repo)) {
    Write-Log "Skipping $repo#$($issue.number) (not in allowlist)"
    continue
  }

  Write-Log "Processing $repo#$($issue.number)"

  if (-not $dryRun) {
    gh issue edit $issue.html_url --remove-label queued --add-label in-progress
  }

  $runUrl = $null
  if ($issue.body -match "https://github.com/.+/actions/runs/\d+") {
    $runUrl = $Matches[0]
  }

  $workRoot = Join-Path $env:TEMP "autopilot\work"
  New-Item -ItemType Directory -Force $workRoot | Out-Null
  $repoDir = Join-Path $workRoot ($repo.Replace("/", "_"))

  if (Test-Path $repoDir) {
    Remove-Item -Recurse -Force $repoDir
  }

  Write-Log "Cloning $repo"
  gh repo clone $repo $repoDir

  Push-Location $repoDir
  try {
    $baseBranch = $env:BASE_BRANCH_OVERRIDE
    if (-not $baseBranch) {
      $baseBranch = (git remote show origin | Select-String "HEAD branch" | ForEach-Object { $_.ToString().Split(':')[-1].Trim() })
    }
    if (-not $baseBranch) { $baseBranch = "main" }

    git checkout $baseBranch
    $branch = "autofix/issue-$($issue.number)"
    git checkout -b $branch

    $prompt = @()
    $prompt += "Repo: $repo"
    $prompt += "Issue: $($issue.title)"
    $prompt += "Issue URL: $($issue.html_url)"
    if ($runUrl) { $prompt += "Run URL: $runUrl" }
    $prompt += "Rules: minimal patch, no unrelated edits, no secrets, run best-effort tests."
    $prompt += "Return a concise plan and apply fixes."
    $promptText = $prompt -join [Environment]::NewLine

    if (-not $dryRun) {
      Write-Log "Running Codex"
      try {
        Invoke-Checked -Command "codex" -Args @($promptText)
      } catch {
        Write-Log "Primary Codex invocation failed, retrying with 'run' subcommand." "WARN"
        Invoke-Checked -Command "codex" -Args @("run", $promptText)
      }
    } else {
      Write-Log "Dry run: skipping Codex"
    }

    $changes = git status --porcelain
    if (-not $changes) {
      Write-Log "No changes detected. Marking blocked."
      if (-not $dryRun) {
        gh issue comment $issue.html_url -b "No changes produced by automation. Marking blocked."
        gh issue edit $issue.html_url --remove-label in-progress --add-label blocked
      }
      continue
    }

    $verification = "skipped"
    if (Test-Path "package.json") {
      $verification = "npm"
      if (-not $dryRun) {
        Invoke-Checked -Command "npm" -Args @("ci")
        Invoke-Checked -Command "npm" -Args @("test")
      }
    } elseif (Test-Path "pyproject.toml" -or Test-Path "requirements.txt") {
      $verification = "python"
      if (-not $dryRun) {
        Invoke-Checked -Command "python" -Args @("-m", "venv", ".autopilot-venv")
        .\.autopilot-venv\Scripts\Activate.ps1
        if (Test-Path "requirements.txt") {
          Invoke-Checked -Command "python" -Args @("-m", "pip", "install", "-r", "requirements.txt")
        }
        Invoke-Checked -Command "pytest" -Args @("-q")
      }
    } elseif ((Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
      $verification = "dotnet"
      if (-not $dryRun) {
        Invoke-Checked -Command "dotnet" -Args @("test")
      }
    }

    if (-not $dryRun) {
      git add -A
      git commit -m "Autofix #$($issue.number)"
      git push -u origin $branch

      $prBody = "Fixes #$($issue.number)" + [Environment]::NewLine
      if ($runUrl) { $prBody += "Run: $runUrl" + [Environment]::NewLine }
      $pr = gh pr create -t "Autofix #$($issue.number)" -b $prBody

      gh issue comment $issue.html_url -b "Opened PR: $pr"
      gh issue edit $issue.html_url --remove-label in-progress --add-label done
    }

    Write-Log "Completed $repo#$($issue.number) (verification=$verification)"
  } catch {
    Write-Log "Error: $_" "ERROR"
    if (-not $dryRun) {
      gh issue comment $issue.html_url -b "Automation failed: $_"
      gh issue edit $issue.html_url --remove-label in-progress --add-label blocked
    }
  } finally {
    Pop-Location
  }
}
