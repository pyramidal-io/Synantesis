#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)-$(uname -m)" != Linux-x86_64 ]]; then
  echo 'This installer targets the Linux amd64 Forgejo validation lane' >&2
  exit 1
fi

tools="${RUNNER_TEMP:?RUNNER_TEMP must be set}/synantesis-tools"
mkdir -p "$tools/otp" "$tools/elixir" "$tools/node" "$tools/bin"

curl -fsSL --retry 3 'https://builds.hex.pm/builds/otp/amd64/ubuntu-22.04/OTP-28.5.0.7.tar.gz' -o "$tools/otp.tar.gz"
echo "38f507761691e3bc4bf4f23eda7f03390341864e71c37555de501695d8bae308  $tools/otp.tar.gz" | sha256sum --check --strict -
tar xzf "$tools/otp.tar.gz" -C "$tools/otp" --strip-components=1
(cd "$tools/otp" && ./Install -minimal "$tools/otp")

curl -fsSL --retry 3 'https://builds.hex.pm/builds/elixir/v1.20.4-otp-28.zip' -o "$tools/elixir.zip"
echo "ea7ff98bc1ed76c663a5d034c863c6fd37e65c9c855b6bbf6ccb2034d806673c  $tools/elixir.zip" | sha256sum --check --strict -
unzip -q "$tools/elixir.zip" -d "$tools/elixir"
chmod +x "$tools/elixir/bin/"*

curl -fsSL --retry 3 'https://nodejs.org/dist/v22.23.2/node-v22.23.2-linux-x64.tar.xz' -o "$tools/node.tar.xz"
echo "d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307  $tools/node.tar.xz" | sha256sum --check --strict -
tar xJf "$tools/node.tar.xz" -C "$tools/node" --strip-components=1

curl -fsSL --retry 3 'https://github.com/orhun/git-cliff/releases/download/v2.12.0/git-cliff-2.12.0-x86_64-unknown-linux-musl.tar.gz' -o "$tools/git-cliff.tar.gz"
echo "c89a7bc55f3c51f391938aa3fa560125109695c1930d927879daea68dd786420  $tools/git-cliff.tar.gz" | sha256sum --check --strict -
tar xzf "$tools/git-cliff.tar.gz" -C "$tools/bin" --strip-components=1 git-cliff-2.12.0/git-cliff

export PATH="$tools/otp/bin:$tools/elixir/bin:$tools/node/bin:$tools/bin:$PATH"
printf '%s\n' "$tools/otp/bin" "$tools/elixir/bin" "$tools/node/bin" "$tools/bin" >> "${GITHUB_PATH:?GITHUB_PATH must be set}"
elixir --version
node --version
git-cliff --version
mix local.hex 2.5.1 --force
mix local.rebar rebar3 https://github.com/erlang/rebar3/releases/download/3.27.0/rebar3 \
  --sha512 0d00494d849fdc521a55142278d1f6ba552954fbd65b80d40df8022f594f05d6c99ed1d731bc263691a04176e11d4c6e126c56ba20dca19c5e42d4ffab2e7e36 \
  --force
