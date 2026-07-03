#!/usr/bin/env bash
# Verify Home Assistant REST and WebSocket APIs are reachable from this host.
# Usage: HA_URL=http://host:8123 HA_TOKEN=xxx ./scripts/verify-ha-connection.sh

set -euo pipefail

HA_URL="${HA_URL:-}"
HA_TOKEN="${HA_TOKEN:-}"
HA_TIMEOUT="${HA_TIMEOUT:-10}"

if [[ -z "$HA_URL" || -z "$HA_TOKEN" ]]; then
  echo "ERROR: Set HA_URL and HA_TOKEN (e.g. source config/homeassistant.env)" >&2
  exit 1
fi

# Strip trailing slash
HA_URL="${HA_URL%/}"

echo "Checking Home Assistant at ${HA_URL} ..."

# --- REST /api/ ---
rest_code=$(curl -sS -o /tmp/ha-api-response.json -w "%{http_code}" \
  --connect-timeout "$HA_TIMEOUT" \
  -H "Authorization: Bearer ${HA_TOKEN}" \
  -H "Content-Type: application/json" \
  "${HA_URL}/api/" || echo "000")

if [[ "$rest_code" == "200" ]]; then
  if grep -q '"message".*"API running' /tmp/ha-api-response.json 2>/dev/null; then
    echo "REST /api/: OK (200, API running)"
  else
    echo "REST /api/: WARN (200 but unexpected body: $(cat /tmp/ha-api-response.json))"
    exit 1
  fi
else
  echo "REST /api/: FAIL (HTTP ${rest_code})"
  [[ -f /tmp/ha-api-response.json ]] && cat /tmp/ha-api-response.json
  exit 1
fi

# --- WebSocket /api/websocket ---
# Derive WS URL from HA_URL if not set
if [[ -z "${HA_WS_URL:-}" ]]; then
  HA_WS_URL="${HA_URL/http:/ws:}"
  HA_WS_URL="${HA_WS_URL/https:/wss:}"
  HA_WS_URL="${HA_WS_URL}/api/websocket"
fi

ws_result=$(python3 - "$HA_WS_URL" "$HA_TOKEN" "$HA_TIMEOUT" <<'PY'
import json
import sys
import ssl

try:
    import websocket
except ImportError:
  # Fallback: stdlib-only check via HTTP upgrade probe is unreliable; require websocket-client
    print("SKIP: install python3-websocket-client for WebSocket check")
    sys.exit(0)

url, token, timeout = sys.argv[1], sys.argv[2], int(sys.argv[3])
ws = websocket.create_connection(url, timeout=timeout, sslopt={"cert_reqs": ssl.CERT_NONE})
try:
    hello = json.loads(ws.recv())
    if hello.get("type") != "auth_required":
        print(f"FAIL: expected auth_required, got {hello}")
        sys.exit(1)
    ws.send(json.dumps({"type": "auth", "access_token": token}))
    auth = json.loads(ws.recv())
    if auth.get("type") == "auth_ok":
        print("OK")
        sys.exit(0)
    print(f"FAIL: {auth}")
    sys.exit(1)
finally:
    ws.close()
PY
)

if [[ "$ws_result" == OK ]]; then
  echo "WebSocket /api/websocket: OK (auth_success)"
elif [[ "$ws_result" == SKIP:* ]]; then
  echo "WebSocket /api/websocket: ${ws_result#SKIP: }"
  echo "Install: pip install websocket-client  (or apt install python3-websocket)"
  exit 1
else
  echo "WebSocket /api/websocket: ${ws_result}"
  exit 1
fi

echo ""
echo "All checks passed."
