# Enterprise Control-Plane Verification

Status: passed with manual deployment prerequisites

## Fixed findings

| ID | Status | Evidence |
| --- | --- | --- |
| F-01 | fixed | `0733a4b` removes unlabeled issue discovery and promotion. |
| F-02 | fixed | `0532832` excludes and defensively skips exhausted `try-3` issues. |
| F-03 | fixed | `35119dc` adds an explicit untrusted-content boundary to Codex prompts. |
| F-04 | fixed | `36daf3c`, `e34d380` enforce sensitive-path and change-size policies. |
| F-05 | fixed | `7bbcf3c`, `bc1e0e8` require supported verification by default and document exceptions. |
| F-06 | fixed | `f15b9f8`, `bc1e0e8` require and document the org mutation token contract. |
| F-07 | fixed | `26cf4f4`, `f2e6e43` repair workflow YAML, add contract tests, and migrate actions to Node.js 24-compatible majors. |
| F-08 | fixed | `c7b10fc` makes pre-opt-in installer notices non-actionable. |

## Validation

- `python tests/validate_workflows.py`: passed, 5 workflow files.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/contract-tests.ps1`: passed.
- `python -m compileall tests`: passed.
- `yamllint` with GitHub Actions-compatible truthy rule disabled: passed.
- `git diff --check`: passed.
- Remote CI run `27290403822`: passed without Node.js runtime deprecation annotations.

## Manual-only findings

- M-01: An administrator must provision `ORG_AUTOPILOT_TOKEN` using a short-lived GitHub App installation token or a fine-grained token with access only to opted-in repositories. Required repository permissions are Contents write, Issues write, and Pull requests write.
- M-02: Secretless Codex authentication remains an architecture decision dependent on provider workload-identity support.
- M-03: A sandboxed staging organization and self-hosted Windows runner are required for a live end-to-end test of issue intake, mutation, verification, push, and pull-request creation.
