# F-07 supported GitHub Action runtimes

Issue Description: Green remote CI warned that checkout and github-script action majors used deprecated Node.js 20.
State: GitHub will force Node.js 24 on June 16, 2026 and remove Node.js 20 on September 16, 2026.
Action: Updated to the verified latest supported majors, `actions/checkout@v6` and `actions/github-script@v9`, including templates.
Result: Workflows use Node.js 24-compatible action releases and CI prevents regression to deprecated majors.
Diff Patch: Updated action majors and added a contract assertion.
Rationale: Platform deprecation warnings are reliability defects with fixed deadlines.
