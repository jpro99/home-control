# Home Assistant setup and BFF connection

Provision Home Assistant for the target home, create a long-lived access token, and confirm the BFF host can reach REST and WebSocket APIs.

## Quick start (Docker — dev/test)

```bash
cd docker
docker compose up -d
```

Open `http://<host>:8123`, complete onboarding, then create a token:

1. Profile (bottom-left) → **Security**
2. **Long-Lived Access Tokens** → **Create Token**
3. Copy the token immediately (shown once)

Copy and edit connection config:

```bash
cp config/ha.env.example config/ha.env
# Set HA_URL and HA_TOKEN
```

Verify from the BFF host (or any machine that should reach HA):

```bash
chmod +x scripts/verify-ha-connection.sh
./scripts/verify-ha-connection.sh
```

## Production (Home Assistant OS)

For the target home appliance, use [Home Assistant OS](https://www.home-assistant.io/installation/) on supported hardware (e.g. Raspberry Pi, NUC, or HA Green). HA OS includes Supervisor and add-on support.

After install:

1. Complete onboarding at `http://homeassistant.local:8123` (or the device IP).
2. Create a long-lived token (same steps as above).
3. Set `HA_URL` to the LAN-reachable base URL the BFF will use.
4. Run `scripts/verify-ha-connection.sh` from the BFF host.

## BFF connection config

| Variable     | Description                                      |
|-------------|--------------------------------------------------|
| `HA_URL`    | Base URL, e.g. `http://192.168.1.100:8123`      |
| `HA_TOKEN`  | Long-lived access token                          |
| `HA_TIMEOUT`| Optional timeout in seconds (default `10`)       |

Template: `config/ha.env.example` → `config/ha.env` (gitignored).

### Endpoints verified

| API        | Path               | Check                                      |
|-----------|--------------------|--------------------------------------------|
| REST      | `GET /api/`        | `200` + `{"message":"API running."}`       |
| WebSocket | `/api/websocket`   | `auth_required` → `auth` → `auth_ok`       |

## Files

- `docker/docker-compose.yml` — containerized HA for dev/test
- `config/ha.env.example` — BFF connection template
- `scripts/verify-ha-connection.sh` — REST + WebSocket verification
- `docs/home-assistant-setup.md` — detailed provisioning guide

## Troubleshooting

- **Connection refused**: confirm HA is running and `HA_URL` uses the address reachable from the BFF host (not `localhost` unless the BFF runs on the same machine).
- **auth_invalid**: regenerate the long-lived token and update `HA_TOKEN`.
- **WebSocket timeout**: check firewalls between BFF and HA; WebSocket uses the same host/port as HTTP(S).
