# Operator Runbook

## Purpose
The operator scans for queued issues and attempts safe fixes using Codex.

## Run locally
```pwsh
$env:ORG = "your-org"
$env:MAX_ISSUES = 3
$env:DRY_RUN = "true"
.\scripts\autopilot-operator.ps1
```

## Environment variables
- `ORG` (required)
- `REPO_ALLOWLIST` (optional, comma-separated)
- `MAX_ISSUES` (default 5)
- `DRY_RUN` (default false)
- `BASE_BRANCH_OVERRIDE` (optional)
- `MAX_CHANGED_FILES` (default 20)
- `MAX_CHANGED_LINES` (default 1000)
- `ALLOW_UNVERIFIED` (default false; approved exceptions only)


## GitHub authorization
The scheduled workflow requires an `ORG_AUTOPILOT_TOKEN` secret backed by a short-lived GitHub App installation token or fine-grained token. Grant access only to opted-in repositories with Issues and Pull requests write plus Contents write. The repository-scoped `GITHUB_TOKEN` cannot perform cross-repository control-plane mutations.
## Behavior
- Only processes issues labeled `autofix` + `queued`
- Skips `risky` and `needs-design`
- Requires a supported verification command unless an approved exception sets `ALLOW_UNVERIFIED=true`
- Opens a PR if changes are safe and tests pass

## Logging
Logs are written to `%TEMP%\autopilot\logs\operator_<date>.log`.
