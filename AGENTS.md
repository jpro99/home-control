# AGENTS.md

Guardrails for human and AI contributors working in the **home-control** repository.

## 1. Canonical Repository

- **Canonical name:** `home-control`
- **GitHub:** `jpro99/home-control`
- **Purpose:** Home automation control plane — orchestration, policy, and audit for premise devices and integrations.

This is the single source of truth for home-control application code, adapters, and operational guardrails. Do not fork guardrails into vendor-specific trees; extend through adapters (see §4).

## 2. Directory Conventions

```text
home-control/
├── AGENTS.md              # contributor guardrails (this file)
├── README.md              # human-facing overview
├── docs/
│   └── adr/               # Architecture Decision Records (ADR-first)
├── src/                   # core domain, orchestration, policy engine
├── adapters/              # vendor/device integrations (isolated behind interfaces)
├── audit/                 # append-only audit schemas, validators, tooling
├── scripts/               # build, verify, and operational helpers
└── .paperclip.yaml        # optional Paperclip runtime sidecar (not canonical logic)
```

Rules:

- **Core logic** lives in `src/` and must not import vendor SDKs directly.
- **Vendor code** lives only under `adapters/<vendor>/` and implements shared interfaces from `src/`.
- **Premise changes** (security surface, network exposure, device trust boundaries) require an ADR in `docs/adr/` before implementation.
- **Audit artifacts** (schemas, integrity checks) live in `audit/`; runtime audit streams are append-only (see §6).
- Do not add machine-local paths, secret values, or provider-specific bindings to markdown guardrails.

## 3. Build Verification Before Push

No change may be pushed without passing the smallest relevant verification for its scope.

### Default checks (when tooling exists)

```sh
# Typecheck / lint (preferred entrypoint once present)
./scripts/verify.sh
# or, when package scripts are defined:
# npm run typecheck && npm run test && npm run build
```

### Push gate

Before `git push`:

1. Run the narrowest check that proves the change (unit tests for logic, adapter contract tests for integrations).
2. If verification tooling is not yet present for a bootstrap change, document what was not run and why in the commit/PR body.
3. Do not push broken builds to `main`.

### Definition of done

A change is done when:

1. Relevant verification passes (or absence is explicitly documented for bootstrap-only edits).
2. Guardrails in this file are respected.
3. Security-surface or premise changes have a merged or draft ADR (see §8).
4. No secrets are committed (see §7).

## 4. Vendor Isolation Behind Adapters

Vendor-specific SDKs, protocols, and device APIs must stay behind adapter boundaries.

- Define interfaces in `src/` (e.g. `DeviceDriver`, `EventBus`, `StateStore`).
- Implement vendor code only in `adapters/<vendor>/`.
- **Forbidden:** direct vendor imports from `src/` or cross-adapter imports.
- Adapter config (API URLs, entity IDs, credentials *references*) belongs in `.paperclip.yaml` or environment — never hard-coded secrets in source.
- Each adapter ships its own tests against the shared interface contract.

When adding a new integration:

1. Extend or confirm the interface in `src/`.
2. Add `adapters/<vendor>/` with an isolated implementation.
3. Document trust boundaries and data flows in an ADR if the integration changes the security surface.

## 5. Security Surface: Confirm + Audit

Any change that expands or alters the **security surface** requires explicit confirmation and audit coverage before merge.

Security surface includes:

- New inbound network listeners or exposed APIs
- New outbound connections to external services
- Broadened device permissions or automation triggers with safety impact
- Authentication, authorization, or credential handling changes
- Physical actuator commands (locks, alarms, HVAC overrides, etc.)

Required workflow:

1. **Confirm** — state the surface change, blast radius, and rollback in an ADR or PR description.
2. **Audit** — ensure the change emits structured audit events (see §6).
3. **Review** — security-surface changes need explicit human or board acknowledgment when policy requires it; do not self-approve high-risk actuator paths.

## 6. Append-Only Audit Integrity

Audit logs are **append-only**. Integrity is non-negotiable.

- Audit records must not be updated or deleted in place; corrections are new compensating entries.
- Each entry should include: timestamp, actor, action, target, outcome, and correlation id where applicable.
- Schemas and validators live in `audit/`; runtime stores must reject mutations to historical records.
- Tests must cover tamper detection or immutability guarantees where the storage backend allows.

## 7. No Secrets in Repository

- **Never** commit API keys, tokens, passwords, private keys, or `.env` files with live credentials.
- Use environment variables, secret managers, or Paperclip secret inputs (declared in `.paperclip.yaml`) for runtime secrets.
- Redact secrets from logs, audit payloads, and example configs.
- If a secret is accidentally committed, rotate it immediately and scrub history per incident response policy.

## 8. ADR-First for Premise Changes

**Premise changes** alter how the system interacts with the physical home or its trust boundaries. These require an ADR *before* implementation.

Premise changes include:

- New device classes or automation categories with safety impact
- Network topology or exposure changes
- Default-deny vs default-allow policy shifts
- Cross-adapter orchestration that affects physical state
- Changes to audit, auth, or emergency override behavior

ADR workflow:

1. Create `docs/adr/NNNN-short-title.md` using the project ADR template.
2. Record context, decision, consequences, and security/audit implications.
3. Link the ADR from the implementing PR.
4. Do not merge premise-changing code without a corresponding ADR.

## 9. Pull Requests

When opening a PR:

- Summarize what changed and which guardrails apply.
- Note verification commands run and their results.
- Call out security-surface impact explicitly (none / low / high).
- Link ADRs for premise or security-surface changes.

## 10. References

- Agent Companies spec (adapter sidecars, package layout): Paperclip `docs/companies/companies-spec.md`
- Runtime-specific adapter and secret config: `.paperclip.yaml` (optional sidecar)
