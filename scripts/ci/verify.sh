#!/usr/bin/env bash
set -euo pipefail

mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix css.check_tokens
mix credo --strict
mix sobelow
mix deps.audit
mix hex.audit
mix excellent_migrations.check_safety
mix test
npm ci --prefix assets
mix test.js
MIX_ENV=dev mix gettext.extract --check-up-to-date
MIX_ENV=dev mix dialyzer.incremental --list-unused-filters
