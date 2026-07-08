# Operations

## Run the test suite

```powershell
pwsh ./tests/run-tests.ps1
```

This runs workflow YAML validation, control-plane contract tests, and Pester 5 unit tests in
one command — the same entry point CI uses.

## CI gate (`.github/workflows/ci.yml`)

CI runs on `ubuntu-latest` for every push/PR to `main` and performs, in order:

1. `python tests/validate_workflows.py` — validates workflow YAML.
2. `./tests/contract-tests.ps1` — validates control-plane contracts.
3. Pester 5.5.0+ unit tests over `./tests` with `Invoke-Pester` (`Run.Exit = $true`,
   `Output.Verbosity = 'Detailed'`).

Pester coverage focuses on the safety- and payload-critical logic: `Assert-SafeChangeSet`
(sensitive-path and diff-budget guards), `Get-ChangedFile` (porcelain parsing), `Search-Issue`
(GraphQL request construction), and the `Autopilot.Common` helpers (`Get-RepoName`,
`Invoke-GhJson`, `Get-LogTail`).

There is no branch-coverage percentage gate in this repo's CI as of this writing — the gate is
pass/fail on the validation, contract, and Pester steps, not a coverage threshold.

## Other CI workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `codeql.yml` | scheduled + push | CodeQL static analysis |
| `pr-lint.yml` | PR | PR metadata/title linting |
| `stale.yml` | scheduled | Stale issue/PR sweep |
| `pages.yml` | push to `main` | Publishes the dashboard to GitHub Pages |

## Manual dispatch

Trigger the operator manually to validate a setup change:

```bash
gh workflow run autopilot-operator.yml -R Coding-Autopilot-System/autopilot-core
```

## Runbooks

- [docs/status.md](../status.md) — status snapshot
- [docs/runbooks/operator.md](../runbooks/operator.md) — operator runbook
- [docs/runbooks/install-to-repo.md](../runbooks/install-to-repo.md) — repo onboarding runbook
- [docs/demos/demo-repo.md](../demos/demo-repo.md) — demo walkthrough using `autopilot-demo`

<!-- docs-verified: cd76345f0837ce2f710ad8bad7bbc9e3de9d5ff0 2026-07-08 -->
