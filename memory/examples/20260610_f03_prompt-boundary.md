# F-03 prompt-injection boundary

Issue Description: Untrusted issue and comment content was mixed with operator instructions.
State: Repository users could place instruction-like text directly in the Codex prompt.
Action: Added explicit security policy and untrusted-content delimiters around all issue data.
Result: The model receives a clear instruction hierarchy and treats issue content as data.
Diff Patch: Added security rules plus BEGIN/END UNTRUSTED markers.
Rationale: Prompt boundaries reduce indirect prompt-injection risk at the AI execution boundary.
