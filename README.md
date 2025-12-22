# Autopilot Core

Organization-level control plane and operator for CI Autopilot.

## Architecture

```
[Workflow Failure]
       |
       v
[autopilot-create-issue.yml]
  - create/update issue (labels)
       |
       v
[autopilot-operator.yml] (self-hosted)
  - scans queued issues
  - runs Codex
  - opens PRs
```

## How it works
- Failures trigger issue intake in the originating repo.
- Issues labeled `autofix` + `queued` are eligible for automation.
- The operator runs on a self-hosted runner and attempts safe fixes.

## Quick start
1) Set org variable `ORG` in GitHub Actions for this repo.
2) Install `autopilot-create-issue.yml` into target repos.
3) Ensure a self-hosted runner is online for this repo.
4) Run `autopilot-operator.yml` manually to validate.

## Current Autopilot Status
<!-- AUTOPILOT-STATUS:START -->
Last updated: 1970-01-01T00:00:00Z
See `docs/status.md` for the full status table.
<!-- AUTOPILOT-STATUS:END -->

## Safety guardrails
- Acts only on `autofix + queued` issues.
- Skips anything labeled `risky` or `needs-design`.
- Minimal diffs, no secrets, no destructive ops.
- Best-effort verification before PR creation.

## Demos
- `docs/demos/demo-repo.md`
- `templates/demo-repo/`
