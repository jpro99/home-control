# home-control

Home automation stack for the target home, centered on [Home Assistant](https://www.home-assistant.io/).

## Quick start (Docker)

For development and BFF connectivity testing, run Home Assistant via Docker Compose:

```bash
cd homeassistant
docker compose up -d
```

Open `http://localhost:8123`, complete onboarding, then create a long-lived access token (see [docs/home-assistant-setup.md](docs/home-assistant-setup.md)).

Verify connectivity from the BFF host:

```bash
export HA_URL=http://localhost:8123
export HA_TOKEN=<your-long-lived-token>
./scripts/verify-ha-connection.sh
```

## Production deployment

For the target home, prefer **Home Assistant OS** on dedicated hardware (Raspberry Pi 4+, NUC, or similar). See [docs/home-assistant-setup.md](docs/home-assistant-setup.md) for OS vs Supervised vs Container guidance.

## Configuration

Copy the example env file and fill in values after provisioning:

```bash
cp config/homeassistant.env.example config/homeassistant.env
```

Connection settings consumed by the BFF:

| Variable | Description |
|----------|-------------|
| `HA_URL` | Base URL (e.g. `http://192.168.1.50:8123`) |
| `HA_TOKEN` | Long-lived access token |
| `HA_WS_URL` | WebSocket URL (optional; derived from `HA_URL` if unset) |

## Layout

```
homeassistant/          Docker Compose stack
config/                 Connection config templates
docs/                   Setup and operations guides
scripts/                Connectivity verification
```
