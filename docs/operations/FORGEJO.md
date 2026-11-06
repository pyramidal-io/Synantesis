# Synantesis native CI

The native workflow is `.forgejo/workflows/ci.yml`. It validates the exact
candidate commit on pull requests to `main`, and runs again on pushes to main.
Manual runs are restricted to main. The two jobs use the isolated general PR
runner and do not reference stored secrets, trusted release runners, Docker
sockets or shared caches.

## Verify

`scripts/ci/install-toolchains.sh` verifies pinned downloads of OTP 28.5.0.7,
Elixir 1.20.4, Node 22.23.2 and git-cliff 2.12.0. It installs Hex 2.5.1 and
checksum-verified rebar3 3.27.0. The workflow sets a UTF-8 locale explicitly.
PostgreSQL 17 is a digest-pinned job service without host-published ports.
`TEST_DB_HOST` selects its hostname; local test runs continue to default to
localhost.

`scripts/ci/verify.sh` preserves the upstream per-change Verify sequence:
formatting, compilation, CSS token checks, Credo, Sobelow, both dependency
audits, migration safety, ExUnit, Vitest, Gettext extraction and Dialyzer.
Upstream nightly excluded suites, flake hunts, browser E2E and binary release
signing require separate qualification before they are enabled here.

## Policy

`scripts/ci/policy.sh` runs native Forgejo workflow schema validation,
actionlint, workflow-isolation regression tests, incoming-commit Gitleaks
and Developer Certificate of Origin sign-off checks. The upstream CLA and
copyright files are preserved as attribution and upstream terms; this fork
uses DCO sign-offs for new contributions.

After actual native qualification, maintainers configure protected main to
require these exact contexts:

- `Synantesis CI / Verify (pull_request)`
- `Synantesis CI / Policy (pull_request)`

The inherited GitHub workflows are restricted to the upstream repository,
so publishing Synantesis source cannot invoke upstream Docker Hub or
licensing automation.

## Source publication

These candidate jobs perform validation. They do not publish source, tags or
releases and receive no publication credential. Maintainers run publication
from separate trusted control after native checks and review have passed.
The public GitHub repository supplies the commit-addressed source link for
deployed Synantesis builds. Publish a build's exact source commit before
deploying it, and inject its full revision when building the release.
