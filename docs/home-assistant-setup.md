# Home Assistant provisioning guide

This document covers standing up Home Assistant for the home-control project and connecting the BFF.

## Choose an install method

| Method | Best for | This repo |
|--------|----------|-----------|
| **Home Assistant OS** | Production home hub | Recommended for target home |
| **Docker Compose** | Dev, CI, supervised-style | `docker/docker-compose.yml` |
| **Supervised** | Debian host with full Supervisor | See [official docs](https://www.home-assistant.io/installation/) |

## Home Assistant OS (recommended for target home)

1. Download the image for your hardware from [home-assistant.io/installation](https://www.home-assistant.io/installation/).
2. Flash to SD/USB per vendor instructions.
3. Boot the device on the home LAN.
4. Browse to `http://homeassistant.local:8123` or the device IP.
5. Create the initial owner account and complete onboarding.

### Static IP (optional but recommended)

Assign a DHCP reservation or static IP so `HA_URL` stays stable for the BFF.

## Docker Compose (dev / test)

From the repo root:

```bash
cd docker
docker compose up -d
```

Logs:

```bash
docker compose logs -f homeassistant
```

Data persists in the `ha_config` Docker volume.

## Long-lived access token

The BFF should use a **long-lived access token**, not the owner password.

1. Log into Home Assistant.
2. Open your **Profile** (username in the sidebar footer).
3. Scroll to **Security** → **Long-Lived Access Tokens**.
4. Click **Create Token**, name it (e.g. `home-control-bff`).
5. Copy the token immediately; it is only shown once.

Store the token in `config/ha.env` as `HA_TOKEN` or in your deployment secret manager.

## BFF connection configuration

```bash
cp config/ha.env.example config/ha.env
```

Edit `config/ha.env`:

```bash
HA_URL=http://192.168.1.100:8123
HA_TOKEN=<paste-token-here>
```

- `HA_URL` must be reachable **from the BFF host**, not only from your laptop.
- Use `https://` if TLS is terminated on HA or a reverse proxy; the verify script upgrades WebSocket to `wss://` automatically.

Add `config/ha.env` to your secret store for deployment; do not commit real tokens.

## Verify connectivity from the BFF host

Run on the machine (or container) that will host the BFF:

```bash
./scripts/verify-ha-connection.sh
```

Expected output:

```
==> Home Assistant connectivity check
    URL: http://192.168.1.100:8123
==> REST GET /api/
REST: OK (HTTP 200, API running)
==> WebSocket ws://192.168.1.100:8123/api/websocket
WebSocket: auth_ok
==> All checks passed
```

### What the script checks

1. **REST** — `GET /api/` with `Authorization: Bearer <token>` must return HTTP 200 and `{"message":"API running."}`.
2. **WebSocket** — connects to `/api/websocket`, responds to `auth_required` with the token, and receives `auth_ok`.

## Network requirements

- BFF host → HA host: TCP **8123** (or 443 if behind HTTPS proxy).
- No extra path prefix; HA serves API at `/api/` and WebSocket at `/api/websocket`.
- If using a reverse proxy, ensure WebSocket upgrade headers are forwarded.

## Next steps

After verification passes, wire `HA_URL` and `HA_TOKEN` into the BFF service environment and implement entity/state consumers against the [Home Assistant REST](https://developers.home-assistant.io/docs/api/rest/) and [WebSocket](https://developers.home-assistant.io/docs/api/websocket/) APIs.
