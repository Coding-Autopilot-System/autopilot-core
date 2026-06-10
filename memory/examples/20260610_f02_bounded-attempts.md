# F-02 bounded attempts

Issue Description: Issues at `try-3` could be selected and executed repeatedly.
State: Search and processing logic did not exclude exhausted issues.
Action: Excluded `try-3` from discovery and added a defensive runtime guard.
Result: Exhausted issues remain available for human review but are not re-executed.
Diff Patch: Added `-label:try-3` and an attempt-limit guard.
Rationale: Bounded retries prevent runaway cost and repeated unsafe mutations.
