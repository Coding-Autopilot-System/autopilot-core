$ErrorActionPreference = "Stop"

function Assert-TextMatch {
  param([string]$Text, [string]$Pattern, [string]$Message)
  if ($Text -notmatch $Pattern) { throw $Message }
}

function Assert-TextNotMatch {
  param([string]$Text, [string]$Pattern, [string]$Message)
  if ($Text -match $Pattern) { throw $Message }
}

$operator = Get-Content -Raw "scripts/autopilot-operator.ps1"
$workflow = Get-Content -Raw ".github/workflows/autopilot-operator.yml"
$installer = Get-Content -Raw ".github/workflows/autopilot-org-installer.yml"
$allWorkflows = (Get-ChildItem -Recurse -File -Include *.yml,*.yaml | ForEach-Object { Get-Content -Raw $_.FullName }) -join "`n"

Assert-TextMatch -Text $operator -Pattern 'label:autofix label:queued' -Message "Operator must require autofix and queued labels."
Assert-TextNotMatch -Text $operator -Pattern 'no:label' -Message "Operator must not execute unlabeled issues."
Assert-TextMatch -Text $operator -Pattern '-label:try-3' -Message "Operator must exclude exhausted issues."
Assert-TextMatch -Text $operator -Pattern 'BEGIN UNTRUSTED ISSUE CONTENT' -Message "Operator must delimit untrusted prompt content."
Assert-TextMatch -Text $operator -Pattern 'Assert-SafeChangeSet' -Message "Operator must validate generated changes."
Assert-TextMatch -Text $operator -Pattern 'ALLOW_UNVERIFIED' -Message "Operator must enforce verification by default."
Assert-TextMatch -Text $workflow -Pattern 'secrets\.ORG_AUTOPILOT_TOKEN' -Message "Workflow must use an explicit org mutation token."
Assert-TextNotMatch -Text $workflow -Pattern 'GH_TOKEN: \$\{\{ secrets\.GITHUB_TOKEN \}\}' -Message "Workflow must not use repository token for org mutations."
Assert-TextMatch -Text $workflow -Pattern 'timeout-minutes: 60' -Message "Operator workflow must allow enough time for the intended batch work."

Assert-TextNotMatch -Text $installer -Pattern 'autofix,queued,docs' -Message "Installer must not queue automation before repository opt-in."

Assert-TextNotMatch -Text $allWorkflows -Pattern 'actions/checkout@v4|actions/github-script@v7' -Message "Workflows must not use deprecated Node.js 20 action majors."

Write-Output "Control-plane contract tests passed."
