# autopilot-core

[![CI](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/ci.yml/badge.svg)](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/ci.yml) [![CodeQL](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/codeql.yml/badge.svg)](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/codeql.yml)


[![CI](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Coding-Autopilot-System/autopilot-core/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Org-level AI autopilot control plane** - scans GitHub issues labeled `autofix + queued`, invokes Codex to generate fixes, and opens pull requests automatically across the Coding-Autopilot-System organization.

Part of the [Coding-Autopilot-System](https://github.com/Coding-Autopilot-System) autonomous CI repair platform alongside [ci-autopilot](https://github.com/Coding-Autopilot-System/ci-autopilot) and [autopilot-demo](https://github.com/Coding-Autopilot-System/autopilot-demo).

## Repo boundary

- `autopilot-core` is the control plane: org-wide intake governance, operator scheduling, PR creation, and rollout visibility.
- `ci-autopilot` is the worker/runtime pattern: the runner-hosted Python agent and workflow assets used to execute repairs.
- `autopilot-demo` is the proof repo: a safe target that demonstrates the full failure-to-fix loop.

## How it works

```mermaid
flowchart LR
    A[CI Failure] --> B[autopilot-create-issue.yml]
    B --> C[Issue: autofix + queued]
    C --> D[autopilot-operator.yml]
    D --> E[Codex Fix Generation]
    E --> F[Pull Request Opened]
    F --> G[Auto-merge / Review]
```

1. A CI failure in any opted-in repo triggers `autopilot-create-issue.yml`, creating an issue labeled `autofix + queued`.
2. `autopilot-operator.yml` runs on a schedule on the self-hosted Windows runner, scanning for labeled issues.
3. For each eligible issue, the operator invokes Codex to generate a targeted fix.
4. The fix is committed to a branch and a pull request is opened in the target repo.
5. `autopilot-org-installer.yml` scans the org hourly and installs the intake workflow into repos that opt in via `.autopilot/opt-in`.

## Quick start

1. Set org variable `ORG` in GitHub Actions for this repo.
2. Configure the least-privilege `ORG_AUTOPILOT_TOKEN` secret for opted-in repository mutations.
3. Install `autopilot-create-issue.yml` into target repos, or use `autopilot-org-installer.yml`.
4. Ensure a self-hosted Windows runner with Codex and `OPENAI_API_KEY` is online.
5. Trigger `autopilot-operator.yml` manually to validate the setup.

## Enterprise proof points

- Centralized control plane with explicit issue-queue handoff instead of opaque direct mutation.
- Auditable lifecycle: CI failure, intake issue, operator run, fix branch, and PR are all visible in GitHub.
- Guardrailed execution: label-gated intake, skip labels for risky work, and verification before PR creation.
- Org-scale rollout path: installer workflow distributes intake automation to opted-in repositories.

## Safety guardrails

- Acts only on issues labeled `autofix + queued`.
- Skips issues labeled `risky` or `needs-design`.
- Minimal diffs only - no secrets, no destructive operations.
- Required supported verification before PR creation, with explicit approved exceptions only.

## Testing

Run the full suite (workflow YAML validation, control-plane contract tests, and
Pester unit tests) with a single command:

```powershell
pwsh ./tests/run-tests.ps1
```

Unit tests (Pester 5) cover the safety- and payload-critical logic:
`Assert-SafeChangeSet` (sensitive-path and diff-budget guards), `Get-ChangedFile`
(porcelain parsing), `Search-Issue` (GraphQL request construction), and the
`Autopilot.Common` helpers (`Get-RepoName`, `Invoke-GhJson`, `Get-LogTail`).

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push/PR to main | Portfolio CI - YAML validation + Pester unit tests (ubuntu-latest) |
| `autopilot-operator.yml` | schedule + dispatch | Core operator - scan issues, run Codex, open PRs |
| `autopilot-org-installer.yml` | hourly + dispatch | Install intake workflow into opted-in repos |
| `autopilot-create-issue.yml` | workflow_run failure | Create intake issue when monitored workflow fails |
| `autopilot-docs-daily.yml` | daily | Update dashboard status page |

## Documentation

- [Wiki](https://github.com/Coding-Autopilot-System/autopilot-core/wiki) - setup guide, architecture, configuration reference
- [Dashboard](https://coding-autopilot-system.github.io/autopilot-core/) - live autopilot status
- [docs/status.md](docs/status.md) - status snapshot
- [docs/runbooks/operator.md](docs/runbooks/operator.md) - operator runbook
- [docs/runbooks/install-to-repo.md](docs/runbooks/install-to-repo.md) - repo onboarding runbook
- [docs/demos/demo-repo.md](docs/demos/demo-repo.md) - demo walkthrough using `autopilot-demo`
