# Autonomyx Multi-Tenant Agent Platform Architecture (Phase 1)

## Scope and intent

This document captures Phase 1 deliverables for evolving this Hermes-derived runtime into a production-grade Autonomyx-aligned platform.

Phase 1 objectives:

1. Assess current state and runtime entry points.
2. Map gaps against Autonomyx Agent Identity + Decide + LangGraph + Langflow target model.
3. Define target module map and layering.
4. Define phased implementation strategy with compatibility boundaries.

---

## Current repository assessment

### Runtime entry points (today)

- `run_agent.py` hosts `AIAgent` and synchronous `run_conversation()` tool-loop orchestration.
- `cli.py` is the interactive CLI shell and command router.
- `gateway/run.py` runs long-lived multi-platform gateway adapters.
- `cron/scheduler.py` executes scheduled jobs and invokes agent runs.
- `hermes_cli/web_server.py` provides FastAPI APIs + static web dashboard.
- `tui_gateway/server.py` and `ui-tui` form TUI split-process mode.

### Tooling model (today)

- Tools are registered globally via `tools.registry` and discovered dynamically by import side effects.
- `model_tools.py` mediates schema exposure and function dispatch through registry.
- Current access controls are mostly environment/toolset-driven, not tenant/agent policy-driven.

### Memory model (today)

- Session memory/history lives in SQLite (`hermes_state.py`) scoped by session id and source.
- Curated long-lived memory is file-based (`tools/memory_tool.py`) in profile-scoped files (`MEMORY.md`, `USER.md`).
- No first-class tenant/agent namespace boundaries, classification, or retention policy enforcement.

### Channels model (today)

- Channels exist through gateway platform adapters, CLI, TUI, web, and cron pathways.
- Channel identity and routing are present, but there is no central channel policy layer enforcing pre-execution decisions.

### Decisioning/audit model (today)

- Logging, usage stats, and session persistence exist.
- No explicit first-class decision records required before action execution.
- Tool, memory, and channel checks are not unified under a formal Decide engine.

### Hidden/global-state risks (today)

- Dynamic import + global registry patterns in tools and model orchestration.
- Process-global mutable tool resolution state in `model_tools.py` (e.g., last resolved tools).
- Mixed context propagation via parameters, env vars, globals, and per-surface session objects.

---

## Gap analysis vs target architecture

## 1) Tenancy

**Gap:** No platform-wide tenant primitive as primary isolation key.

**Required:** Tenant-aware storage keys, runtime context propagation, and enforcement at every boundary.

## 2) Agent identity + sponsor accountability

**Gap:** Agent execution identity is runtime/config-derived, not lifecycle-governed principal records.

**Required:** Durable `AgentPrincipal` tied to tenant, sponsor, lifecycle, trust/risk tier, and policy bindings.

## 3) Decide-first execution

**Gap:** Current paths may execute tools/messages/workflows directly.

**Required:** Every action must produce a `DecisionResult` record before execution proceeds.

## 4) Memory governance

**Gap:** Memory persistence exists, but lacks tenant-agent namespaces, sensitivity, retention, and policy checks.

**Required:** Governed memory namespaces and policy-aware read/write operations with auditable events.

## 5) Tool governance

**Gap:** Global registry plus toolset filtering is not deny-by-default per tenant/agent/workflow.

**Required:** Per-tenant enablement, per-agent authorization, optional per-workflow constraints, and attribution.

## 6) Channel governance

**Gap:** Transport adapters perform routing but not centralized channel policy enforcement.

**Required:** Channel abstraction with inbound/outbound normalization + decision guard rails + audit.

## 7) LangGraph orchestration

**Gap:** Complex workflows are procedural runtime logic; no durable graph substrate.

**Required:** LangGraph-backed workflow execution with checkpoints, decision gates, and resumability.

## 8) Langflow composition

**Gap:** No canonical visual-flow import/compile bridge.

**Required:** Flow spec management + validation + compilation into executable graph definitions.

---

## Target module map (Phase 1 design)

Create additive platform modules under `autonomyx/`:

```text
autonomyx/
  context/
    tenant_context.py
    request_context.py
    runtime_attribution.py
    resolver.py
  identity/
    principals.py
    registry.py
    lifecycle.py
    sponsor_resolution.py
  decide/
    engine.py
    models.py
    guards/
      lifecycle_guard.py
      capability_guard.py
      tool_guard.py
      memory_guard.py
      channel_guard.py
      budget_guard.py
      model_guard.py
    recorder.py
  audit/
    decision_events.py
    audit_events.py
    usage_attribution.py
    trace_context.py
  memory/
    namespace.py
    policy.py
    read_service.py
    write_service.py
    retention.py
    isolation.py
  tools/
    registry.py
    authorization.py
    invocation.py
    result_capture.py
  channels/
    registry.py
    authorization.py
    inbound_dispatcher.py
    outbound_dispatcher.py
    binding_service.py
    adapters/
      cli_channel.py
      web_channel.py
      api_channel.py
      cron_channel.py
      webhook_channel.py
      slack_channel.py
  graph/
    registry.py
    execution.py
    state_store.py
    checkpoint_adapter.py
    nodes/
      decision_node.py
      memory_node.py
      tool_node.py
      model_node.py
      channel_node.py
      subagent_node.py
  flow/
    definition_service.py
    validation_service.py
    compiler.py
    binding_service.py
  compat/
    local_mode.py
```

---

## Explicit architecture layering

1. **Tenancy Layer**: resolves tenant boundary and isolation keys.
2. **Identity Layer**: resolves agent and sponsor principals.
3. **Decide Layer**: policy + lifecycle + capability checks and decision record.
4. **Execution Layer**:
   - Simple path: Hermes conversational loop with policy adapters.
   - Structured path: LangGraph execution for durable workflows.
5. **Composition Layer**: Langflow-compatible flow specs compiled to graph defs.
6. **Governed Resources**: memory, tools, channels, model invocation.
7. **Audit/Usage Layer**: immutable decision + audit event pipelines.

Rule: no resource action without attributed context + decision allow.

---

## Integration strategy with existing Hermes runtime

- Preserve current `AIAgent` loop as a compatibility-compatible execution worker.
- Insert context resolution + Decide checks at entry points (CLI, gateway, cron, web, TUI).
- Wrap tool/memory/channel/model operations with policy-bound services.
- Use LangGraph for durable, branching, checkpointed workflows where orchestration complexity justifies it.
- Keep default local mode for developer ergonomics (`local tenant`, `local sponsor`, `local agent`) isolated in compat module.

---

## Migration strategy (high-level)

1. Introduce new tables and services behind feature flags.
2. Start dual-writing decision/audit events while preserving existing behavior.
3. Move tool/memory/channel actions through governance services incrementally.
4. Introduce graph execution path for selected flows first.
5. Promote graph/flow execution as default for production tenants.

---

## Backward compatibility strategy

- Default local mode auto-resolves:
  - `tenant_id=local-default`
  - `sponsor_subject_id=local-user`
  - `agent_id=local-hermes-agent`
- Compatibility layer isolated under `autonomyx/compat`.
- Production mode requires explicit tenant/agent/sponsor resolution and disallows local fallback unless enabled by config.

---

## Phase plan summary

- **Phase 1 (this change):** architecture + data model + migration design assets.
- **Phase 2:** tenancy/identity/decide primitives + persistence + context propagation.
- **Phase 3:** governed memory/tools/channels + usage attribution.
- **Phase 4:** LangGraph runtime integration.
- **Phase 5:** Langflow bridge and compiler.
- **Phase 6:** cross-surface runtime integration + subagent constraints + compatibility hardening.
- **Phase 7:** test expansion + examples + cleanup.

