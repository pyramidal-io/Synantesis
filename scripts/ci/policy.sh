#!/usr/bin/env bash
set -euo pipefail

policy_tools="${RUNNER_TEMP:?RUNNER_TEMP must be set}/synantesis-policy"
mkdir -p "$policy_tools"
curl -fsSL --retry 3 'https://code.forgejo.org/forgejo/runner/releases/download/v13.0.0/forgejo-runner-13.0.0-linux-amd64' -o "$policy_tools/forgejo-runner"
echo "cfcfe65e9ed5c9a4b344acfdbc3c32210b274c005a5888f46967c4d988177707  $policy_tools/forgejo-runner" | sha256sum --check --strict -
chmod +x "$policy_tools/forgejo-runner"
"$policy_tools/forgejo-runner" validate --directory .

curl -fsSL --retry 3 'https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz' -o "$policy_tools/actionlint.tar.gz"
echo "8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8  $policy_tools/actionlint.tar.gz" | sha256sum --check --strict -
tar xzf "$policy_tools/actionlint.tar.gz" -C "$policy_tools" actionlint
"$policy_tools/actionlint" -config-file .forgejo/actionlint.yaml -ignore 'specifying action "https://' .forgejo/workflows/*.yml
python3 scripts/ci/check-workflows.py
python3 -m unittest discover -s scripts/tests -p 'test_*.py'

curl -fsSL --retry 3 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.0/gitleaks_8.30.0_linux_x64.tar.gz' -o "$policy_tools/gitleaks.tar.gz"
echo "79a3ab579b53f71efd634f3aaf7e04a0fa0cf206b7ed434638d1547a2470a66e  $policy_tools/gitleaks.tar.gz" | sha256sum --check --strict -
tar xzf "$policy_tools/gitleaks.tar.gz" -C "$policy_tools" gitleaks

case "${EVENT_NAME:?EVENT_NAME must be set}" in
  pull_request) base="${BASE_SHA:?BASE_SHA must be set}" ;;
  push) base="${BEFORE_SHA:?BEFORE_SHA must be set}" ;;
  workflow_dispatch) base="$(git rev-parse HEAD^)" ;;
  *) echo 'Unsupported verification event' >&2; exit 1 ;;
esac

if [[ "$base" == 0000000000000000000000000000000000000000 ]]; then
  echo 'An initial import must be reviewed before Actions is enabled' >&2
  exit 1
fi
git cat-file -e "$base^{commit}"
"$policy_tools/gitleaks" git --log-opts="$base..HEAD" --no-banner --redact
python3 scripts/ci/check-dco.py "$base..HEAD"
