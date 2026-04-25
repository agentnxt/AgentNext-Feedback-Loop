# Governed Memory, Tools, Channels, and Decisions (Phase 1)

## Purpose

Define the governance contract for four first-class pillars:

1. Memory
2. Tools
3. Channels
4. Decisions (and audit)

---

## Current-state mapping

## Memory

- Session history persisted in SQLite (`hermes_state.py`).
- Curated memory tool stores markdown files (`tools/memory_tool.py`).
- Missing tenant/agent policy segmentation and explicit access-event auditing.

## Tools

- Global tool registry and dispatch (`tools/registry.py`, `model_tools.py`).
- Tool availability mostly requirement-based (env/toolset), not principal-based authorization.

## Channels

- Multiple channels supported via gateway, CLI, web, TUI, cron.
- Missing centralized policy + decision gate per channel operation.

## Decisions

- No explicit decision object required before action execution.
- Event records are fragmented across logs/session data.

---

## Target governance model

## 1) Decision-first invariant

All actions must call `DecideEngine.evaluate(DecisionRequest)` before execution.

Actions include:

- memory read/write
- tool invoke
- channel receive/send
- model call
- graph transition
- subagent spawn
- schedule execution

## 2) Memory governance

Memory namespace key pattern:

`tenant_id / agent_id / workspace_or_conversation / namespace_type`

Namespace types:

- `agent_private`
- `tenant_shared`
- `workflow_state`
- `session_ephemeral`

Each read/write requires:

- memory capability
- classification clearance
- retention policy compatibility

## 3) Tool governance

Tool use requires all:

- tool globally registered
- tenant enabled
- agent permitted
- optional workflow-level allowlist
- lifecycle + budget guards pass

All invocations emit:

- decision event (allow/deny)
- invocation audit record
- usage attribution record

## 4) Channel governance

Channel actions are normalized:

- inbound: `ChannelInboundEvent`
- outbound: `ChannelOutboundAction`

Both require channel guard checks and decision records.

---

## Explicit service contract

- `DecideEngine`
- `ExecutionDecisionRecorder`
- `MemoryPolicyService`
- `ToolAuthorizationService`
- `ChannelAuthorizationService`
- `DecisionEventRecorder`
- `AuditEventRecorder`

These services are shared by direct runtime paths and graph node wrappers.

---

## Example decision envelope (conceptual)

```json
{
  "tenant_id": "tnt_acme",
  "agent_id": "agt_ops_assistant",
  "sponsor_subject_id": "usr_123",
  "action": "tool.invoke",
  "target_resource": "tool:terminal",
  "required_capability": "tool.execute.terminal",
  "trace_id": "trc_...",
  "graph_run_id": "grn_...",
  "conversation_id": "conv_...",
  "session_id": "sess_..."
}
```

---

## Migration strategy

1. Add decision record persistence and recorder service.
2. Wrap existing tool dispatch with authorization service.
3. Introduce memory namespace service and enforce on memory reads/writes.
4. Introduce channel dispatcher wrappers around existing gateway/web/CLI routes.
5. Move graph and flow paths to same governance contract.

---

## Backward compatibility

- Compatibility mode maps legacy sessions to local defaults.
- Compatibility mode still emits decisions/audit records (source tagged `compat_local`).
- Production mode disallows missing tenant/agent context.

