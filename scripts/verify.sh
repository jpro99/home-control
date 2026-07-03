#!/usr/bin/env bash
# Canonical verification entrypoint (see AGENTS.md §3).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> home-control verify"

if [[ -x "${SCRIPT_DIR}/verify-ha-connection.sh" ]]; then
  # When HA_URL/HA_TOKEN are unset, the HA script exits non-zero with usage — expected in CI without secrets.
  if [[ -f "${SCRIPT_DIR}/../config/ha.env" ]] || [[ -n "${HA_URL:-}" && -n "${HA_TOKEN:-}" ]]; then
    "${SCRIPT_DIR}/verify-ha-connection.sh"
  elif [[ -x "${SCRIPT_DIR}/test-verify-ha-connection.sh" ]]; then
    echo "    run: mock HA connectivity test (no config/ha.env)"
    "${SCRIPT_DIR}/test-verify-ha-connection.sh"
  else
    echo "    skip: HA connectivity (no config/ha.env or HA_URL/HA_TOKEN)"
  fi
else
  echo "    skip: verify-ha-connection.sh not present"
fi

echo "==> verify complete"
