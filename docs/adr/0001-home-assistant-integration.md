# 0001. Home Assistant as first premise integration

Date: 2026-07-03
Status: accepted

## Context

home-control needs a live premise hub to orchestrate devices. Home Assistant (HA) is the chosen first integration: it exposes REST and WebSocket APIs, supports long-lived access tokens, and can run on dedicated home hardware (HA OS) or in Docker for dev/test.

The BFF (future `src/` service) will connect to HA over the home LAN using `HA_URL` and `HA_TOKEN`. This expands the security surface: a new outbound trust relationship from the BFF to HA, and optional inbound exposure if HA is containerized with host networking for device discovery.

## Decision

1. Adopt Home Assistant as the initial premise adapter target under `adapters/homeassistant/` (implementation follows interface work in `src/`).
2. Provide **Docker Compose** (`docker/docker-compose.yml`) for dev/test only; production on target home uses **Home Assistant OS**.
3. Store connection settings in `config/ha.env` (gitignored) from `config/ha.env.example`; never commit tokens.
4. Verify connectivity with `scripts/verify-ha-connection.sh` (REST `GET /api/` and WebSocket auth handshake).
5. Require board/human acknowledgment before the BFF performs physical actuator commands through HA; read-only/state subscription is the initial scope.

## Consequences

- Engineers can develop against a containerized HA instance without target hardware.
- Live end-to-end verification remains blocked until HA is provisioned on the home LAN and `config/ha.env` is populated.
- Future adapter code must stay isolated per AGENTS.md §4; no direct HA SDK imports from `src/`.

## Security / audit impact

- **Surface:** outbound HTTPS/WS from BFF host to HA; Docker dev stack may use `network_mode: host` for mDNS/device discovery.
- **Credentials:** long-lived HA tokens are secrets; rotate on leak.
- **Audit:** BFF→HA actions must emit append-only audit events once orchestration exists (see `audit/`).
- **Rollback:** revoke HA token; stop Docker stack; remove BFF env config.
