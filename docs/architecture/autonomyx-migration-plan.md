# Autonomyx Migration Plan (Phase 1)

## Goals

- Introduce tenant-first governance without breaking existing Hermes local workflows.
- Migrate incrementally with dual-run and compatibility controls.

## Safe migration path

1. Add new governance tables (`db/migrations/0001_...`).
2. Keep existing `hermes_state.py` schema untouched.
3. Add feature flags:
   - `AUTONOMYX_ENABLE_DECIDE`
   - `AUTONOMYX_ENABLE_GOVERNED_TOOLS`
   - `AUTONOMYX_ENABLE_GOVERNED_MEMORY`
   - `AUTONOMYX_ENABLE_GOVERNED_CHANNELS`
   - `AUTONOMYX_ENABLE_GRAPH_RUNTIME`
4. Start with write-only decision/audit mirror mode.
5. Move to enforce mode per channel/tenant.

## Backward-compatible operation

- Local mode auto-creates local tenant/sponsor/agent identities.
- Existing commands and runtime paths remain valid while governance services are introduced.

## Reversibility

- Down migration provided for new tables.
- Feature flags allow fallback to compatibility path during rollout incidents.

## Data backfill strategy

- Map existing session sources to default local tenant and agent.
- Backfill only metadata references first (non-blocking), then full policy bindings.

