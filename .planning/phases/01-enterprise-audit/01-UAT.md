# Enterprise Control-Plane Audit

Audit source: `gsd-audit-fix --severity all --max 8`

## Findings

| ID | Severity | Classification | Description | File references |
| --- | --- | --- | --- | --- |
| F-01 | high | auto-fixable | Unlabeled issues bypass the documented `autofix + queued` authorization gate. | `scripts/autopilot-operator.ps1` |
| F-02 | high | auto-fixable | Issues with exhausted `try-3` attempts can be selected repeatedly. | `scripts/autopilot-operator.ps1` |
| F-03 | high | auto-fixable | Untrusted issue and comment text is passed to Codex without prompt-injection boundaries. | `scripts/autopilot-operator.ps1` |
| F-04 | high | auto-fixable | The operator stages arbitrary generated files without sensitive-path or change-size policy enforcement. | `scripts/autopilot-operator.ps1` |
| F-05 | high | auto-fixable | Changes without supported verification can still be pushed and marked done. | `scripts/autopilot-operator.ps1` |
| F-06 | high | auto-fixable | The operator workflow uses the repository-scoped token for org-wide mutations. | `.github/workflows/autopilot-operator.yml`, `docs/runbooks/operator.md` |
| F-07 | medium | auto-fixable | CI intentionally ignores workflow YAML errors and has no control-plane contract tests. | `.github/workflows/ci.yml`, `tests/contract-tests.ps1` |
| F-08 | medium | auto-fixable | The installer creates actionable autofix issues for repositories that have not opted in. | `.github/workflows/autopilot-org-installer.yml` |
| M-01 | high | manual-only | Provisioning a production GitHub App or fine-grained token and org-level RBAC requires administrator action. | Organization settings |
| M-02 | medium | manual-only | Replacing secret-based Codex auth with workload identity depends on provider support and an architecture decision. | `.github/workflows/autopilot-operator.yml` |

## Verification policy

- Run `pwsh -NoProfile -File tests/contract-tests.ps1` after each applicable fix once the contract suite exists.
- Run `git diff --check` before every commit.
- Retain this audit and the final verification report as GSD evidence.
