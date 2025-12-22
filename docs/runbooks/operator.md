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

## Behavior
- Only processes issues labeled `autofix` + `queued`
- Skips `risky` and `needs-design`
- Attempts best-effort verification
- Opens a PR if changes are safe and tests pass

## Logging
Logs are written to `%TEMP%\autopilot\logs\operator_<date>.log`.
