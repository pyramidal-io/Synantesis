#!/usr/bin/env python3
"""Keep Synantesis candidate workflows within the credentialless runner tier."""

import re
from pathlib import Path

import yaml

CHECKOUT = (
    "https://code.forgejo.org/actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683"
)
ALLOWED_EXPRESSIONS = {
    "github.event.pull_request.head.sha || github.sha",
    "github.event_name",
    "github.event.pull_request.base.sha",
    "github.event.before",
}
GUARD = "github.event_name == 'pull_request' || github.ref == 'refs/heads/main'"


def validate(path: Path) -> None:
    text = path.read_text()
    workflow = yaml.load(text, Loader=yaml.BaseLoader)
    if not isinstance(workflow, dict):
        raise ValueError("workflow must be a mapping")
    if set(workflow.get("on", {})) - {"push", "pull_request", "workflow_dispatch"}:
        raise ValueError("unsupported workflow event")
    if workflow.get("permissions") != {"contents": "read"}:
        raise ValueError("workflow must request only contents:read")
    if re.search(
        r"\bsecrets\s*(?:\.|\[)|\b(?:github|forgejo)\s*(?:\[|\.\s*token\b)", text, re.I
    ):
        raise ValueError("candidate workflows cannot reference credentials")
    for expression in re.findall(r"\$\{\{(.*?)\}\}", text, re.S):
        if expression.strip() not in ALLOWED_EXPRESSIONS:
            raise ValueError(
                "workflow expression is outside the approved metadata inputs"
            )
    jobs = workflow.get("jobs", {})
    if workflow.get("name") != "Synantesis CI" or set(jobs) != {"verify", "policy"}:
        raise ValueError("the Verify and Policy gates must both exist")
    if {job.get("name") for job in jobs.values()} != {"Verify", "Policy"}:
        raise ValueError("required gate names must remain stable")
    for job in jobs.values():
        if job.get("runs-on") != "forgejo-untrusted-pr-v1" or job.get("if") != GUARD:
            raise ValueError("job must use the isolated tier and main-ref guard")
        if not 1 <= int(job.get("timeout-minutes", "0")) <= 180:
            raise ValueError("job timeout must be bounded")
        if set(job) & {"uses", "secrets", "container", "permissions"}:
            raise ValueError("job cannot override execution or credentials")
        for service in job.get("services", {}).values():
            if not re.fullmatch(
                r"[^\s]+@sha256:[0-9a-f]{64}", service.get("image", "")
            ):
                raise ValueError("service image must use an immutable digest")
            if set(service) - {"image", "env"}:
                raise ValueError("service cannot publish ports or override isolation")
        for step in job.get("steps", []):
            if "if" in step:
                raise ValueError(
                    "candidate steps must not add implicit context expressions"
                )
            if "uses" in step and (
                step["uses"] != CHECKOUT
                or step.get("with", {}).get("persist-credentials") != "false"
            ):
                raise ValueError("only the pinned credentialless checkout is allowed")


def native_paths(root: Path) -> list[Path]:
    return sorted(
        path for path in root.iterdir() if path.suffix.lower() in {".yml", ".yaml"}
    )


def main() -> None:
    paths = native_paths(Path(".forgejo/workflows"))
    if paths != [Path(".forgejo/workflows/ci.yml")]:
        raise SystemExit(
            "the native CI workflow must exist and be the only candidate workflow"
        )
    for path in paths:
        try:
            validate(path)
        except (ValueError, TypeError) as error:
            raise SystemExit(f"{path}: {error}") from error
        print(f"Validated isolated workflow policy for {path}")


if __name__ == "__main__":
    main()
