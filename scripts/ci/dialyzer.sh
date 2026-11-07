#!/usr/bin/env bash
set -euo pipefail

report_memory() {
  # A run killed at the job limit leaves no other record of its peak.
  cat /sys/fs/cgroup/memory.peak /sys/fs/cgroup/memory.events 2>/dev/null || true
}
trap report_memory EXIT

mix deps.get
mix compile
mix dialyzer.incremental --list-unused-filters
