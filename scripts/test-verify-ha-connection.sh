#!/usr/bin/env bash
# End-to-end test: mock HA server + verify-ha-connection.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${MOCK_HA_PORT:-18123}"
TOKEN="${MOCK_HA_TOKEN:-test-token}"
MOCK_PID=""

if [[ ! -d "${SCRIPT_DIR}/node_modules/ws" ]]; then
  npm install --prefix "${SCRIPT_DIR}" --silent
fi

cleanup() {
  if [[ -n "${MOCK_PID}" ]] && kill -0 "${MOCK_PID}" 2>/dev/null; then
    kill "${MOCK_PID}" 2>/dev/null || true
    wait "${MOCK_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

MOCK_HA_PORT="${PORT}" MOCK_HA_TOKEN="${TOKEN}" node "${SCRIPT_DIR}/mock-ha-server.mjs" &
MOCK_PID=$!

for _ in $(seq 1 20); do
  if curl -sS -o /dev/null "http://127.0.0.1:${PORT}/api/" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

HA_URL="http://127.0.0.1:${PORT}" HA_TOKEN="${TOKEN}" "${SCRIPT_DIR}/verify-ha-connection.sh"
echo "test-verify-ha-connection: PASS"
