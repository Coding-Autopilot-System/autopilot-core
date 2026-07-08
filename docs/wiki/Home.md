# autopilot-core Wiki

`autopilot-core` is the **control plane** of the Coding-Autopilot-System autonomous CI-repair
platform. It owns org-wide intake governance, operator scheduling, PR creation, and rollout
visibility for the autofix loop.

## Role in the CAS portfolio

CAS ships three cooperating repos for CI self-repair:

| Repo | Role |
|---|---|
| **autopilot-core** (this repo) | Control plane: org-wide intake governance, operator scheduling, PR creation |
| [ci-autopilot](https://github.com/Coding-Autopilot-System/ci-autopilot) | Worker/runtime: self-hosted-runner agent that inventories the issue queue |
| [autopilot-demo](https://github.com/Coding-Autopilot-System/autopilot-demo) | Proof repo: safe target demonstrating the full failure-to-fix loop |

## Quickstart

1. Set the org variable `ORG` in GitHub Actions for this repo.
2. Configure the least-privilege `ORG_AUTOPILOT_TOKEN` secret for opted-in repository mutations.
3. Install `autopilot-create-issue.yml` into target repos, or use `autopilot-org-installer.yml`.
4. Ensure a self-hosted Windows runner with Codex and `OPENAI_API_KEY` is online.
5. Trigger `autopilot-operator.yml` manually to validate the setup.

Full detail: [README Quick start](../../README.md#quick-start).

## Where to go next

- [Architecture](Architecture.md) — the intake-to-PR flow and its trust boundaries
- [Operations](Operations.md) — verified run/test/CI commands
- [Decisions](Decisions.md) — index of recorded architectural decisions

<!-- docs-verified: cd76345f0837ce2f710ad8bad7bbc9e3de9d5ff0 2026-07-08 -->
