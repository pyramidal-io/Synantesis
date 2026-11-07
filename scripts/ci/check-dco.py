#!/usr/bin/env python3
"""Verify sign-off provenance on non-merge incoming commits."""

import subprocess
import sys


def main() -> int:
    commits = subprocess.check_output(
        ["git", "rev-list", "--no-merges", sys.argv[1]], text=True
    ).splitlines()
    for commit in commits:
        email = subprocess.check_output(
            ["git", "show", "-s", "--format=%ae", commit], text=True
        ).strip()
        message = subprocess.check_output(
            ["git", "show", "-s", "--format=%B", commit], text=True
        )
        trailers = subprocess.check_output(
            ["git", "interpret-trailers", "--parse"], input=message, text=True
        )
        signed = any(
            line.lower().startswith("signed-off-by:")
            and line.lower().endswith(f"<{email.lower()}>")
            for line in trailers.splitlines()
        )
        if not signed:
            print(
                f"Commit {commit} has no sign-off matching its author", file=sys.stderr
            )
            return 1
    print(f"Verified DCO sign-off for {len(commits)} incoming commits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
