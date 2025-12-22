# Install to Repo

Copy `.github/workflows/autopilot-create-issue.yml` into the target repo and update the `workflows:` list to match the CI workflows you want to monitor.

## Required labels
Create labels in the target repo if they do not exist:
- `autofix`, `human`
- `queued`, `in-progress`, `blocked`, `done`
- `safe-small`, `risky`, `needs-design`
- `ci`, `tests`, `deps`, `docs`, `infra`, `security`

## Notes
- The intake workflow creates issues on failures and applies `autofix`, `queued`, `safe-small`, `ci`.
- The operator will only act on issues that satisfy guardrails.
