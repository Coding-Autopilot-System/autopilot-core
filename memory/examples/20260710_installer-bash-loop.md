# Installer Bash loop termination

Issue Description: The scheduled Autopilot Org Installer failed before processing repositories with `syntax error: unexpected end of file`.
State: The workflow opened a Bash `for repo` loop without a matching `done`.
Action: Added the missing `done` and a workflow validation check that runs `bash -n` on the embedded installer script.
Result: The installer script now parses before GitHub Actions executes it.
Diff Patch: Updated the installer workflow and `tests/validate_workflows.py`.
Rationale: Workflow YAML validation alone cannot detect syntax errors inside multiline Bash blocks.
