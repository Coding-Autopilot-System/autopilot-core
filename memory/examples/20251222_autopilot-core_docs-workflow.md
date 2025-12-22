# Autopilot docs workflow token and defaults

Issue Description:
Docs workflow failed due to missing org context and API access for issue search.

State:
Workflow reported a configuration error and never ran jobs.

Action:
Added issues read permission, defaulted ORG to repository owner, and allowed an ORG_READ_TOKEN override.

Result:
Workflow can run with default org and proper permissions.

Rationale:
Defaults reduce configuration drift and ensure GitHub API queries succeed.

Diff Patch:
```diff
commit 1685a44293505df0fa2d5f7a7aa968a3d81a7261
Author: Kim Harjamaki <ogeon@msn.com>
Date:   Mon Dec 22 23:20:48 2025 +0200

    Harden docs workflow token and defaults

diff --git a/.github/workflows/autopilot-docs-daily.yml b/.github/workflows/autopilot-docs-daily.yml
index 412350c..b26ed43 100644
--- a/.github/workflows/autopilot-docs-daily.yml
+++ b/.github/workflows/autopilot-docs-daily.yml
@@ -9,13 +9,14 @@ on:
 permissions:
   contents: write
   pull-requests: write
+  issues: read
 
 jobs:
   docs:
     runs-on: ubuntu-latest
     env:
-      ORG: ${{ vars.ORG }}
-      GH_TOKEN: ${{ github.token }}
+      ORG: ${{ vars.ORG || github.repository_owner }}
+      GH_TOKEN: ${{ secrets.ORG_READ_TOKEN || github.token }}
     steps:
       - name: Checkout
         uses: actions/checkout@v4
```
