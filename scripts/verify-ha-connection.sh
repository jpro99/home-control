#!/usr/bin/env bash
# Verify Home Assistant REST (/api/) and WebSocket (/api/websocket) from the BFF host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load config/ha.env when present (repo-local or cwd).
for env_file in "${REPO_ROOT}/config/ha.env" "./config/ha.env"; do
  if [[ -f "${env_file}" ]]; then
    # shellcheck disable=SC1090
    set -a
    source "${env_file}"
    set +a
    break
  fi
done

HA_URL="${HA_URL:-}"
HA_TOKEN="${HA_TOKEN:-}"
HA_TIMEOUT="${HA_TIMEOUT:-10}"

usage() {
  cat <<'EOF'
Usage: scripts/verify-ha-connection.sh

Environment (or config/ha.env):
  HA_URL    Base URL, e.g. http://192.168.1.100:8123
  HA_TOKEN  Long-lived access token

Checks:
  1. GET  {HA_URL}/api/          (REST, Bearer token)
  2. WS   {HA_URL}/api/websocket (auth_required → auth → auth_ok)
EOF
}

if [[ -z "${HA_URL}" || -z "${HA_TOKEN}" ]]; then
  echo "error: HA_URL and HA_TOKEN are required" >&2
  usage >&2
  exit 1
fi

HA_URL="${HA_URL%/}"
export HA_TIMEOUT

echo "==> Home Assistant connectivity check"
echo "    URL: ${HA_URL}"

# --- REST ---
echo "==> REST GET /api/"
rest_body="$(mktemp)"
rest_code="$(
  curl -sS -o "${rest_body}" -w '%{http_code}' \
    --connect-timeout "${HA_TIMEOUT}" \
    --max-time "${HA_TIMEOUT}" \
    -H "Authorization: Bearer ${HA_TOKEN}" \
    -H "Content-Type: application/json" \
    "${HA_URL}/api/"
)"

if [[ "${rest_code}" != "200" ]]; then
  echo "REST: FAILED (HTTP ${rest_code})" >&2
  cat "${rest_body}" >&2 || true
  rm -f "${rest_body}"
  exit 1
fi

if ! grep -q '"message":"API running."' "${rest_body}" 2>/dev/null; then
  echo "REST: unexpected body:" >&2
  cat "${rest_body}" >&2
  rm -f "${rest_body}"
  exit 1
fi

rm -f "${rest_body}"
echo "REST: OK (HTTP 200, API running)"

# --- WebSocket ---
ws_scheme="ws"
if [[ "${HA_URL}" == https://* ]]; then
  ws_scheme="wss"
fi
ws_host="${HA_URL#*://}"
WS_URL="${ws_scheme}://${ws_host}/api/websocket"

echo "==> WebSocket ${WS_URL}"
node "${SCRIPT_DIR}/verify-ha-websocket.mjs" "${WS_URL}" "${HA_TOKEN}"

echo "==> All checks passed"
