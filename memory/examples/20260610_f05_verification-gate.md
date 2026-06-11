# F-05 verification gate

Issue Description: The operator could push changes and mark issues done without running tests.
State: Unsupported repositories silently used `verification=skipped`.
Action: Blocked unverified changes by default and documented an explicit exception flag.
Result: PR creation now requires supported verification unless an operator approves an exception.
Diff Patch: Added the `ALLOW_UNVERIFIED` gate and runbook configuration.
Rationale: Verification is a release gate, not advisory metadata.
