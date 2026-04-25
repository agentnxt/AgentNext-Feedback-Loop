# LangGraph + Langflow Integration Architecture (Phase 1)

## Objectives

- Integrate LangGraph as the durable orchestration substrate.
- Integrate Langflow as operator-facing flow composition that compiles to executable graph definitions.
- Ensure both systems are governed by tenancy, identity, decisions, and audit policies.

---

## Current-state observations

- Orchestration is largely imperative in `run_agent.py`, gateway handlers, and cron workflows.
- No persistent graph-run registry/checkpoint abstraction across channels.
- No formal flow definition service translating visual workflows to runtime graph specs.

---

## Design principles

1. LangGraph is not bolt-on; it is the durable orchestration layer for complex workflows.
2. Langflow artifacts are not demo JSON; they compile into tenant-versioned graph specs.
3. Decision gates wrap graph transitions and node actions.
4. Every node action carries attribution context (tenant, agent, sponsor, trace, session/conversation/graph_run).

---

## Target integration model

## A. Graph definition model

`graph_definitions` + `graph_versions` hold normalized graph specs:

- tenant-scoped ownership
- semantic versioning
- status flags (`draft`, `active`, `deprecated`)
- policy binding references
- checksum/provenance metadata

## B. Graph execution model

`GraphExecutionService`:

- loads graph version
- resolves attribution context
- requests execution decision before start
- executes node-by-node with checkpoint persistence
- emits transition, decision, audit, and usage events

`GraphStateStore`:

- stores runtime graph state and node outputs
- keeps checkpoint/resume tokens
- enforces tenant + graph-run isolation

`GraphCheckpointAdapter`:

- maps LangGraph checkpoint semantics onto platform persistence

## C. Node wrapper model

All node wrappers are policy-aware:

- `decision_check_node`
- `memory_read_node` / `memory_write_node`
- `tool_call_node`
- `model_call_node`
- `channel_action_node`
- `subagent_node`

Each wrapper:

1. builds `DecisionRequest`
2. calls `DecideEngine`
3. records `DecisionEvent`
4. executes action only if allowed
5. records `AuditEvent` + usage attribution

## D. Langflow compilation model

`FlowDefinitionService` stores source flow specs.

`FlowValidationService` validates:

- node schema
- supported component set
- policy hooks
- prohibited direct-execution escapes

`FlowToGraphCompiler` transforms flow specs to normalized graph specs:

- deterministic compile output
- policy hook insertion points
- explicit channel/tool/memory constraints

`FlowBindingService` binds flow versions to:

- tenant agents
- channels
- schedules
- webhook endpoints

---

## How channels trigger graph runs

1. Channel adapter normalizes inbound event.
2. Tenant + agent + sponsor resolved.
3. Decide check for `channel.receive` and `graph.start`.
4. Bound flow version resolved, compiled graph version selected.
5. Graph run started with full attribution context.
6. Outbound channel actions inside graph pass through channel guard + audit.

---

## Governance requirements inside graph runtime

- deny-by-default tool invocation.
- memory access denied without namespace + policy match.
- model usage checked against model permission + budget guard.
- subagents require explicit delegated capability envelope.

---

## Migration plan (LangGraph/Langflow specific)

1. Add graph/flow schema and services (phase 2/3 foundation).
2. Introduce one reference graph runtime path behind feature flag.
3. Add Langflow compiler and import endpoint for curated component subset.
4. Bind selected channel triggers to graph execution.
5. Expand to cron and webhook triggers.

---

## Risks and tradeoffs

- **Risk:** dual orchestration paths (legacy loop + graph runtime) complexity.
  - **Mitigation:** explicit routing policy and progressive migration.
- **Risk:** over-permissive flow components.
  - **Mitigation:** allowlist-based flow validation + forced policy nodes.
- **Risk:** checkpoint consistency under failures.
  - **Mitigation:** transactional state transitions + idempotency keys.

