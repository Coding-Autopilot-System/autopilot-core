# F-07 operator timeout safety

Issue Description: The GitHub Actions operator job could time out after marking an issue `in-progress`, leaving it stranded until a later manual cleanup.
State: The workflow timeout was too short for the intended batch work of clone, Codex, dependency install, and tests.
Action: Increased `.github/workflows/autopilot-operator.yml` timeout to 60 minutes and added a contract assertion in `tests/contract-tests.ps1`.
Result: The operator job now has enough time for its designed batch work, and CI prevents the timeout from being reduced unnoticed.
Diff Patch: Updated the workflow timeout and added a workflow contract check.
Rationale: Batch automation should not strand claim-state on a predictable timeout boundary.
