# Autopilot Core Documentation

Welcome to the **Autopilot Core** documentation. 

`autopilot-core` serves as the centralized control plane for the Coding-Autopilot-System platform. It acts as an organizational AI autopilot, orchestrating autonomous issue intake, bug fixing, and pull request generation for opted-in repositories across the organization.

## Overview

The autopilot platform is composed of three primary parts:
- **`autopilot-core` (This Repository)**: The control plane. Manages org-wide intake governance, schedules the operator, creates pull requests, and maintains rollout visibility.
- **`ci-autopilot`**: The runtime pattern. Contains the Python agent and workflow assets executed by runners to perform the actual repairs.
- **`autopilot-demo`**: A demonstration repository. Provides a safe target for illustrating the end-to-end failure-to-fix loop.

## Key Features

- **Centralized Control Plane**: Operates via explicit GitHub Issues queueing rather than making opaque direct mutations to source code.
- **Auditable Lifecycle**: Every step—from CI failure to intake issue, operator run, fix branch generation, and PR creation—is transparent and traceable in GitHub.
- **Guardrailed Execution**: Uses explicit label-gating (e.g., `autofix + queued`), skips risky work, and verifies fixes before creating Pull Requests.
- **Automated Rollout**: An installer workflow automatically distributes the intake automation to any repository in the organization that opts in.

## Getting Started

To learn more about the technical details, read the [Architecture Guide](architecture.md).

If you are looking to set up or configure the operator, please refer to the [Operator Runbook](runbooks/operator.md) and the [Repo Onboarding Runbook](runbooks/install-to-repo.md).
