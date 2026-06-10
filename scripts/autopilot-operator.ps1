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

function Search-Issues {
  param([string]$SearchQuery, [int]$First)
  $gql = @'
query($q:String!, $first:Int!) {
  search(query:$q, type:ISSUE, first:$first) {
    nodes {
      ... on Issue {
        number
        title
        url
        body
        labels(first:20) { nodes { name } }
        repository { nameWithOwner }
      }
    }
  }
}
'@
  $resp = gh api graphql -f query="$gql" -f q="$SearchQuery" -F first=$First
  if (-not $resp) { return @() }
  $data = $resp | ConvertFrom-Json
  if (-not $data -or -not $data.data -or -not $data.data.search) { return @() }
  return $data.data.search.nodes
}

$issues = @()
$query = "org:$org is:issue label:autofix label:queued -label:blocked -label:risky -label:needs-design"
$issues += Search-Issues -SearchQuery $query -First $maxIssues

if (-not $issues -or $issues.Count -eq 0) {
  Write-Log "No issues found."
  exit 0
}

foreach ($issue in $issues) {
  if (-not $issue -or -not $issue.repository) {
    Write-Log "Skipping issue with missing repository metadata." "WARN"
    continue
  }
  $repo = $issue.repository.nameWithOwner
  if (-not $repo) {
    Write-Log "Skipping issue with empty repository name." "WARN"
    continue
  }
  if ($allowlist.Count -gt 0 -and ($allowlist -notcontains $repo)) {
    Write-Log "Skipping $repo#$($issue.number) (not in allowlist)"
    continue
  }

  Write-Log "Processing $repo#$($issue.number)"

  $attemptLabels = @("try-1", "try-2", "try-3")
  $existingLabels = @()
  if ($issue.labels) {
    $existingLabels = $issue.labels.nodes | ForEach-Object { $_.name }
  }
  $attempt = 1
  if ($existingLabels -contains "try-2") { $attempt = 3 }
  elseif ($existingLabels -contains "try-1") { $attempt = 2 }
  $attemptLabel = $attemptLabels[$attempt - 1]

  if (-not $dryRun) {
    gh issue edit $issue.url --remove-label queued --add-label in-progress
    if ($existingLabels -notcontains $attemptLabel) {
      gh issue edit $issue.url --add-label $attemptLabel
    }
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

    $latestHuman = $null
    $commentHistory = @()
    try {
      $comments = Invoke-GhJson -Args @("api", "repos/$repo/issues/$($issue.number)/comments", "-f", "per_page=100", "-f", "sort=created", "-f", "direction=desc")
      if ($comments) {
        $latestHuman = $comments | Where-Object { $_.user.type -eq "User" -and $_.user.login -ne "github-actions[bot]" } | Select-Object -First 1
        $commentHistory = $comments | Sort-Object created_at | ForEach-Object {
          "[$($_.user.login)] $($_.body)"
        }
      }
    } catch {
      Write-Log "Failed to load comments for $repo#$($issue.number): $_" "WARN"
    }

    $commandsRun = New-Object System.Collections.Generic.List[string]
    $filesChanged = @()
    $prompt = @()
    $prompt += "Repo: $repo"
    $prompt += "Issue: $($issue.title)"
    $prompt += "Issue URL: $($issue.url)"
    if ($runUrl) { $prompt += "Run URL: $runUrl" }
    if ($latestHuman) {
      $prompt += "Latest human guidance from $($latestHuman.user.login):"
      $prompt += $latestHuman.body
      if (-not $dryRun) {
        $guidanceNote = @(
          "Autopilot note:",
          "Using latest human guidance from $($latestHuman.user.login) posted at $($latestHuman.created_at).",
          "Excerpt:",
          ($latestHuman.body.Substring(0, [Math]::Min(600, $latestHuman.body.Length)))
        ) -join [Environment]::NewLine
        gh issue comment $issue.url -b $guidanceNote
      }
    }
    if ($commentHistory.Count -gt 0) {
      $prompt += "Full comment history (oldest to newest):"
      $prompt += ($commentHistory -join [Environment]::NewLine)
    }
    $prompt += "Rules: minimal patch, no unrelated edits, no secrets, run best-effort tests."
    $prompt += "Return a concise plan and apply fixes."
    $promptText = $prompt -join [Environment]::NewLine

    if (-not $dryRun) {
      Write-Log "Running Codex"
      $commandsRun.Add("codex <prompt>")
      try {
        Invoke-Checked -Command "codex" -Args @($promptText)
      } catch {
        Write-Log "Primary Codex invocation failed, retrying with 'run' subcommand." "WARN"
        $commandsRun.Add("codex run <prompt>")
        Invoke-Checked -Command "codex" -Args @("run", $promptText)
      }
    } else {
      Write-Log "Dry run: skipping Codex"
    }

    $changes = git status --porcelain
    if (-not $changes) {
      Write-Log "No changes detected. Marking blocked."
      if (-not $dryRun) {
        gh issue comment $issue.url -b "No changes produced by automation. Marking blocked."
        gh issue edit $issue.url --remove-label in-progress --add-label blocked
        gh issue edit $issue.url --add-label low
        $audit = @(
          "Autopilot attempt: $attemptLabel",
          "Result: no changes",
          "Commands: $([string]::Join(', ', $commandsRun))"
        ) -join [Environment]::NewLine
        gh issue comment $issue.url -b $audit
      }
      continue
    }

    $filesChanged = (git diff --name-only) -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $verification = "skipped"
    $confidence = "low"
    $issueLog = Join-Path $env:TEMP ("autopilot\\logs\\issue_" + $repo.Replace("/", "_") + "_" + $issue.number + ".log")
    if (Test-Path "package.json") {
      $verification = "npm"
      $confidence = "medium"
      if (-not $dryRun) {
        $commandsRun.Add("npm ci")
        Invoke-CheckedLogged -Command "npm" -Args @("ci") -LogPath $issueLog
        $commandsRun.Add("npm test")
        Invoke-CheckedLogged -Command "npm" -Args @("test") -LogPath $issueLog
        $confidence = "high"
      }
    } elseif (Test-Path "pyproject.toml" -or Test-Path "requirements.txt") {
      $verification = "python"
      $confidence = "medium"
      if (-not $dryRun) {
        $commandsRun.Add("python -m venv .autopilot-venv")
        Invoke-CheckedLogged -Command "python" -Args @("-m", "venv", ".autopilot-venv") -LogPath $issueLog
        .\.autopilot-venv\Scripts\Activate.ps1
        if (Test-Path "requirements.txt") {
          $commandsRun.Add("python -m pip install -r requirements.txt")
          Invoke-CheckedLogged -Command "python" -Args @("-m", "pip", "install", "-r", "requirements.txt") -LogPath $issueLog
        }
        $commandsRun.Add("pytest -q")
        Invoke-CheckedLogged -Command "pytest" -Args @("-q") -LogPath $issueLog
        $confidence = "high"
      }
    } elseif ((Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
      $verification = "dotnet"
      $confidence = "medium"
      if (-not $dryRun) {
        $commandsRun.Add("dotnet test")
        Invoke-CheckedLogged -Command "dotnet" -Args @("test") -LogPath $issueLog
        $confidence = "high"
      }
    }

    if (-not $dryRun) {
      git add -A
      git commit -m "Autofix #$($issue.number)"
      git push -u origin $branch

      $prBody = "Fixes #$($issue.number)" + [Environment]::NewLine
      if ($runUrl) { $prBody += "Run: $runUrl" + [Environment]::NewLine }
      $pr = gh pr create -t "Autofix #$($issue.number)" -b $prBody

      gh issue comment $issue.url -b "Opened PR: $pr"
      gh issue edit $issue.url --remove-label in-progress --add-label done
      gh issue edit $issue.url --add-label $confidence

      $audit = @(
        "Autopilot attempt: $attemptLabel",
        "Result: success",
        "Verification: $verification",
        "Confidence: $confidence",
        "Files changed: $([string]::Join(', ', $filesChanged))",
        "Commands: $([string]::Join(', ', $commandsRun))"
      ) -join [Environment]::NewLine
      $tail = Get-LogTail -LogPath $issueLog -Lines 40
      if ($tail) {
        $audit += [Environment]::NewLine + "Log tail:" + [Environment]::NewLine + ($tail -join [Environment]::NewLine)
      }
      gh issue comment $issue.url -b $audit
    }

    Write-Log "Completed $repo#$($issue.number) (verification=$verification)"
  } catch {
    Write-Log "Error: $_" "ERROR"
    if (-not $dryRun) {
      gh issue comment $issue.url -b "Automation failed: $_"
      gh issue edit $issue.url --remove-label in-progress --add-label blocked
      gh issue edit $issue.url --add-label low
      $audit = @(
        "Autopilot attempt: $attemptLabel",
        "Result: failure",
        "Commands: $([string]::Join(', ', $commandsRun))"
      ) -join [Environment]::NewLine
      $tail = Get-LogTail -LogPath $issueLog -Lines 40
      if ($tail) {
        $audit += [Environment]::NewLine + "Log tail:" + [Environment]::NewLine + ($tail -join [Environment]::NewLine)
      }
      gh issue comment $issue.url -b $audit
    }
  } finally {
    Pop-Location
  }
}
