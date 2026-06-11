# F-08 non-actionable opt-in notice

Issue Description: The installer queued an autofix issue in repositories that had not opted in.
State: A notification issue itself satisfied the operator execution gate.
Action: Changed the pre-opt-in notice to an unlabeled informational issue.
Result: Non-opted-in repositories cannot be enrolled through an automated issue side effect.
Diff Patch: Removed actionable labels and clarified the notice title.
Rationale: Enrollment must be an explicit repository-owner decision.
