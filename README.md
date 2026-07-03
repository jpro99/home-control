# home-control

Home automation control plane — orchestration, policy, and audit for premise devices and integrations.

## Repository

This is the canonical **`home-control`** repository (`jpro99/home-control`).

## Contributing

Read **[AGENTS.md](./AGENTS.md)** before making changes. It defines build verification, directory layout, vendor adapter isolation, security-surface rules, append-only audit integrity, secret handling, and ADR-first workflow for premise changes.

## Layout (planned)

```text
src/        core domain and orchestration
adapters/   vendor-specific integrations (isolated)
audit/      append-only audit schemas and tooling
docs/adr/   architecture decision records
```
