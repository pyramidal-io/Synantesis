#!/usr/bin/env bash
set -euo pipefail

run_tests() {
  # The application adopts proxy variables at boot, which reroutes requests
  # that tests stub or expect to fail. Tests need no egress after deps.get.
  local -a test_env=(env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy)

  if [[ "$(id -u)" != 0 ]]; then
    "${test_env[@]}" mix test
    return
  fi

  # Root ignores file permissions, so denied-access tests need a normal user.
  local user=synantesis-ci home=/home/synantesis-ci
  useradd --create-home "$user"
  cp -a "$HOME/.mix" "$HOME/.hex" "$home/"
  chown -R "$user:$user" "$home" .
  setpriv --reuid="$user" --regid="$user" --init-groups \
    "${test_env[@]}" HOME="$home" mix test
}

mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix css.check_tokens
mix credo --strict
mix sobelow
mix deps.audit
mix hex.audit
mix excellent_migrations.check_safety
run_tests
npm ci --prefix assets
mix test.js
MIX_ENV=dev mix gettext.extract --check-up-to-date
