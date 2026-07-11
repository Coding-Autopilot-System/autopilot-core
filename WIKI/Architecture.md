# Architecture

Autopilot Core operates as a stateless polling engine managing organizational webhooks.

## Org-Level Invocation Flow

\\\mermaid
graph TD;
    GitHub[GitHub Org Webhooks] --> Poller[Issue Poller]
    Poller --> Queue[Autofix Task Queue]
    Queue --> Dispatcher[Codex Dispatcher]
    Dispatcher -->|Delegates to AI| Codex[Codex Agent]
    Codex --> GitOps[GitOps Committer]
    GitOps -->|Creates PR| GitHub
\\\

## Auto-Scaling
Because it's a stateless control plane, multiple instances of Autopilot-Core can run simultaneously, picking tasks off the queue to achieve massive parallel issue resolution across hundreds of repositories.
