# home-control

Home automation control plane — orchestration, policy, and audit for premise devices and integrations.

## Repository

This is the canonical **`home-control`** repository (`jpro99/home-control`).

## Contributing

Read **[AGENTS.md](./AGENTS.md)** before making changes. It defines build verification, directory layout, vendor adapter isolation, security-surface rules, append-only audit integrity, secret handling, and ADR-first workflow for premise changes.

## Layout

```text
src/        core domain and orchestration
adapters/   vendor-specific integrations (isolated)
audit/      append-only audit schemas and tooling
docs/adr/   architecture decision records
docker/     container stacks for dev/test (see docs/home-assistant-setup.md)
config/     connection templates (secrets gitignored)
scripts/    build, verify, and operational helpers
```

## Home Assistant (HOM-13)

Home Assistant is the first premise integration. Provisioning, BFF connection config, and connectivity verification are documented in **[docs/home-assistant-setup.md](./docs/home-assistant-setup.md)**.

Quick start (Docker — dev/test):

```bash
cd docker
docker compose up -d
```

Copy and edit connection config, then verify from the BFF host:

```bash
cp config/ha.env.example config/ha.env
# Set HA_URL and HA_TOKEN
./scripts/verify.sh
```

For production on target home hardware, use [Home Assistant OS](https://www.home-assistant.io/installation/). See the setup guide for token creation and LAN reachability requirements.

### Local test (no real HA required)

```bash
./scripts/test-verify-ha-connection.sh
```

Runs a mock HA server and exercises REST `/api/` and WebSocket `/api/websocket` through `scripts/verify-ha-connection.sh`.
