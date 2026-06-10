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

## Behavior
- Only processes issues labeled `autofix` + `queued`
- Skips `risky` and `needs-design`
- Requires a supported verification command unless an approved exception sets `ALLOW_UNVERIFIED=true`
- Opens a PR if changes are safe and tests pass

## Logging
Logs are written to `%TEMP%\autopilot\logs\operator_<date>.log`.
