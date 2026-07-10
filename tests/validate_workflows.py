from pathlib import Path
import subprocess

import yaml


def main() -> None:
    workflows = sorted(Path(".github/workflows").glob("*.yml"))
    if not workflows:
        raise SystemExit("No workflow files found")

    for workflow in workflows:
        with workflow.open(encoding="utf-8") as stream:
            yaml.safe_load(stream)
        print(f"OK: {workflow}")

    with Path(".github/workflows/autopilot-org-installer.yml").open(encoding="utf-8") as stream:
        installer = yaml.safe_load(stream)
    script = installer["jobs"]["installer"]["steps"][1]["run"]
    result = subprocess.run(["bash", "-n"], input=script, text=True, capture_output=True)
    if result.returncode:
        raise SystemExit(f"Installer Bash syntax error: {result.stderr.strip()}")
    print("OK: autopilot-org-installer Bash syntax")

    print(f"Validated {len(workflows)} workflow files")


if __name__ == "__main__":
    main()
