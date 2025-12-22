# Labels

## Intent labels
- `autofix`: eligible for automation
- `human`: requires human handling

## State labels
- `queued`: waiting for automation
- `in-progress`: operator is working
- `blocked`: automation failed or needs input
- `done`: completed by automation

## Risk labels
- `safe-small`: minimal change expected
- `risky`: requires human review
- `needs-design`: needs architectural input

## Area labels
- `ci`
- `tests`
- `deps`
- `docs`
- `infra`
- `security`

## Confidence labels
- `high`
- `medium`
- `low`

## Allowed transitions
- `queued` -> `in-progress` -> `done`
- `queued` -> `blocked`
- `blocked` -> `queued` (after human unblock)
