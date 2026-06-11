# F-07 CI contracts

Issue Description: CI ignored YAML parser errors and did not test control-plane safety contracts.
State: Invalid workflows and authorization regressions could merge with green CI.
Action: Repaired fragile workflow heredocs, added workflow validation and control-plane contract tests, and made CI fail on errors.
Result: CI now enforces workflow syntax and critical operator safety boundaries.
Diff Patch: Added tests and replaced warn-only validation.
Rationale: Control-plane safeguards require executable regression tests.
