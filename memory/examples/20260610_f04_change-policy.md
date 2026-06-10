# F-04 generated change-set policy

Issue Description: The operator staged every generated file without policy checks.
State: Sensitive files or unexpectedly large patches could be committed automatically.
Action: Added changed-file discovery and sensitive-path, file-count, and line-count guards.
Result: Unsafe change sets fail before verification, staging, push, or PR creation.
Diff Patch: Added `Assert-SafeChangeSet` and configurable limits.
Rationale: AI-generated output needs a deterministic enforcement boundary.
