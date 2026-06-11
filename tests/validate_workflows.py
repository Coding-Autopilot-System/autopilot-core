from pathlib import Path

import yaml


def main() -> None:
    workflows = sorted(Path(".github/workflows").glob("*.yml"))
    if not workflows:
        raise SystemExit("No workflow files found")

    for workflow in workflows:
        with workflow.open(encoding="utf-8") as stream:
            yaml.safe_load(stream)
        print(f"OK: {workflow}")

    print(f"Validated {len(workflows)} workflow files")


if __name__ == "__main__":
    main()
