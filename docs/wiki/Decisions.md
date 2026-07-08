# Decisions

This repo tracks two decision trails:

## Phase summaries (`.planning/phases/`)

| Phase | Topic |
|---|---|
| [01-enterprise-audit](../../.planning/phases/01-enterprise-audit/) | Enterprise hardening audit — CODEOWNERS, workflow permission tightening, operator timeout coverage, Pester unit-test extension (see commit `cd76345`) |

## Architecture Decision Records (`docs/adr/`)

The [`docs/adr/`](../adr/README.md) directory is the formal ADR home for this repo, governed by
the rule that any major technical decision or new dependency must be recorded there (Context /
Decision / Consequences, sequentially numbered). No ADR files have been recorded yet as of this
writing — the directory currently holds only the governance README describing the convention.
Future architectural decisions (e.g., changes to the intake/operator contract) should land there
and be indexed on this page.

<!-- docs-verified: cd76345f0837ce2f710ad8bad7bbc9e3de9d5ff0 2026-07-08 -->
