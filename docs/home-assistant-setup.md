# Home Assistant setup

This guide covers provisioning Home Assistant for the target home and connecting the BFF.

## Deployment options

| Method | Best for | Notes |
|--------|----------|-------|
| **Home Assistant OS** | Production (recommended) | Dedicated appliance image; includes Supervisor, add-ons, and easy updates |
| **Home Assistant Supervised** | Linux server you already manage | Full Supervisor on Debian; more ops overhead |
| **Docker Container** | Dev, CI, BFF integration testing | Use `homeassistant/docker-compose.yml` in this repo |

### Home Assistant OS (production)

1. Download the image for your hardware from [home-assistant.io/installation](https://www.home-assistant.io/installation/).
2. Flash to SD card / SSD (Raspberry Pi Imager, balenaEtcher, etc.).
3. Boot the device on the home LAN and browse to `http://homeassistant.local:8123`.
4. Complete onboarding (create admin account, set location/timezone).
5. Note the static IP or set a DHCP reservation for stable BFF access.

### Docker (development)

```bash
cd homeassistant
docker compose up -d
```

First boot may take several minutes. UI: `http://localhost:8123`.

## Create a long-lived access token

Tokens are required for REST and WebSocket API access from the BFF.

1. Sign in to Home Assistant.
2. Click your **profile** (bottom-left).
3. Scroll to **Long-Lived Access Tokens**.
4. Click **Create Token**, name it (e.g. `bff-service`), copy the token immediately.
5. Store the token in your secrets manager or `config/homeassistant.env` (never commit).

The token does not expire unless revoked. Rotate by creating a new token, updating the BFF, then deleting the old one.

## BFF connection config

After provisioning, set these in `config/homeassistant.env`:

```bash
HA_URL=http://<ha-host>:8123
HA_TOKEN=<long-lived-token>
# Optional; defaults to HA_URL with ws/wss scheme
# HA_WS_URL=ws://<ha-host>:8123/api/websocket
```

### API endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET {HA_URL}/api/` | Health check; returns `{"message":"API running."}` with valid token |
| `WS {HA_URL}/api/websocket` | Real-time state and event stream |

Both require the `Authorization: Bearer <token>` header (REST) or auth message after WebSocket connect.

## Verify from the BFF host

```bash
source config/homeassistant.env   # or export HA_URL / HA_TOKEN manually
./scripts/verify-ha-connection.sh
```

Expected output on success:

```
REST /api/: OK (200, API running)
WebSocket /api/websocket: OK (auth_success)
```

## Network requirements

- BFF host must reach Home Assistant on port **8123** (HTTP) or **443** if behind reverse proxy.
- If using TLS, set `HA_URL=https://...` and ensure `HA_WS_URL=wss://...`.
- mDNS (`homeassistant.local`) works on the same LAN; use a static IP or DNS name for server-to-server calls.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Connection refused | HA running? Firewall allows 8123? Correct IP? |
| 401 Unauthorized | Token valid and not revoked? `Authorization: Bearer` header set? |
| WebSocket auth failed | Token copied without whitespace? HA version supports API? |
| Slow first start | Normal on Docker; wait 2–5 minutes after `compose up` |
