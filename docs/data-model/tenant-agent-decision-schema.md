# Tenant-Agent-Decision Data Model (Phase 1)

This document defines the canonical domain entities for the Autonomyx-aligned multi-tenant platform.

## Conventions

- IDs are opaque strings (`tnt_*`, `agt_*`, etc.) or UUIDs.
- Every tenant-owned table includes `tenant_id` and tenant-scope indexes.
- Every mutable lifecycle table includes `created_at`, `updated_at`.
- Soft-delete optional via `deleted_at` for safety/migrations.

---

## Identity and tenancy entities

### tenants
- **Purpose:** top-level isolation boundary.
- **Ownership boundary:** global (platform), tenant-owned rows.
- **Key fields:** `tenant_id`, `name`, `slug`, `status`, `created_at`.
- **Indexes:** unique `slug`, status index.
- **Constraints:** immutable `tenant_id`; unique slug.
- **Tenancy rules:** root owner of all tenant-scoped resources.
- **Lifecycle:** `provisioning -> active -> suspended -> deprovisioned`.

### users
- Purpose: actor identity catalog.
- Key fields: `user_id`, `subject_type`, `subject_ref`, `email`, `status`.
- Constraints: unique (`subject_type`, `subject_ref`).

### tenant_members
- Purpose: bind users to tenant roles.
- Key fields: `tenant_id`, `user_id`, `role`, `membership_state`.
- Indexes: (`tenant_id`, `user_id`) unique.
- Lifecycle: invited/active/suspended/removed.

### sponsors
- Purpose: accountability principal for agent operations.
- Key fields: `sponsor_id`, `tenant_id`, `sponsor_subject_id`, `sponsor_type`, `status`.
- Constraints: unique (`tenant_id`, `sponsor_subject_id`, `sponsor_type`).

### agents
- Purpose: durable agent registry.
- Key fields: `agent_id`, `tenant_id`, `display_name`, `agent_type`, `status`.
- Indexes: (`tenant_id`, `agent_id`) unique, status index.

### agent_identities
- Purpose: full Autonomyx identity envelope.
- Key fields: lifecycle, trust/risk tiers, policy ids, auth profile id, timestamps.
- Constraints: one active identity row per (`tenant_id`, `agent_id`).

### agent_lifecycle_events
- Purpose: immutable lifecycle audit trail.
- Key fields: `event_id`, `tenant_id`, `agent_id`, `from_state`, `to_state`, `reason`, `actor_subject_id`.
- Indexes: (`tenant_id`, `agent_id`, `created_at`).

### subagent_relationships
- Purpose: parent/child delegation mapping.
- Key fields: `relationship_id`, `tenant_id`, `parent_agent_id`, `child_agent_id`, `delegation_scope`, `is_ephemeral`.
- Constraints: deny cross-tenant unless policy flag set.

---

## Policy and capability entities

### capabilities
- Purpose: normalized capability vocabulary.
- Fields: `capability_id`, `name`, `resource_type`, `action`.

### policies
- Purpose: policy definitions (json conditions/rulesets).
- Fields: `policy_id`, `tenant_id`, `policy_type`, `version`, `document`, `status`.
- Indexes: (`tenant_id`, `policy_type`, `status`).

### policy_bindings
- Purpose: bind policy objects to agents/workflows/channels/tools/memory scopes.
- Fields: `binding_id`, `tenant_id`, `binding_target_type`, `binding_target_id`, `policy_id`.
- Constraints: unique per target+policy type.

### budget_policies
- Purpose: usage budgets and rate limits.
- Fields: `budget_policy_id`, `tenant_id`, `limits_json`, `windowing_json`, `status`.

### auth_profiles
- Purpose: auth mode and credential references.
- Fields: `auth_profile_id`, `tenant_id`, `auth_type`, `config_json`, `status`.

### secrets / credential_bindings
- Purpose: secret metadata and bindings (no plaintext values in DB).
- Fields: `secret_id`, `tenant_id`, `provider`, `handle_ref`, `scope_type`, `scope_id`.

---

## Graph and flow entities

### graph_definitions
- Purpose: logical graph identity.
- Fields: `graph_definition_id`, `tenant_id`, `name`, `description`, `owner_agent_id`.

### graph_versions
- Purpose: immutable executable graph specs.
- Fields: `graph_version_id`, `graph_definition_id`, `tenant_id`, `version`, `spec_json`, `checksum`, `status`.
- Constraints: unique (`tenant_id`, `graph_definition_id`, `version`).

### graph_runs
- Purpose: runtime execution instances.
- Fields: `graph_run_id`, `tenant_id`, `graph_version_id`, `agent_id`, `status`, `state_json`, `trace_id`.
- Indexes: (`tenant_id`, `agent_id`, `created_at`).

### flow_definitions
- Purpose: Langflow-style authored flow metadata.
- Fields: `flow_definition_id`, `tenant_id`, `name`, `source_format`, `source_json`, `status`.

### flow_bindings
- Purpose: bind flows to channels/agents/schedules.
- Fields: `flow_binding_id`, `tenant_id`, `flow_definition_id`, `binding_type`, `binding_target_id`, `status`.

---

## Channel/session/message entities

### channel_endpoints
- Purpose: concrete endpoint config (webhook URL, slack channel, etc.).
- Fields: `channel_endpoint_id`, `tenant_id`, `channel_type`, `endpoint_ref`, `config_json`, `status`.

### channel_bindings
- Purpose: binds endpoint to agent/flow with policy references.
- Fields: `channel_binding_id`, `tenant_id`, `channel_endpoint_id`, `agent_id`, `flow_definition_id`, `channel_policy_id`, `status`.

### conversations
- Purpose: normalized conversation identity.
- Fields: `conversation_id`, `tenant_id`, `channel_binding_id`, `subject_ref`, `status`.

### sessions
- Purpose: runtime session partition under conversation.
- Fields: `session_id`, `tenant_id`, `agent_id`, `conversation_id`, `status`, `started_at`, `ended_at`.

### messages
- Purpose: message/event transcript.
- Fields: `message_id`, `tenant_id`, `session_id`, `conversation_id`, `role`, `content`, `metadata_json`, `created_at`.
- Indexes: full-text optional by tenant.

### workspaces
- Purpose: project/work context boundaries.
- Fields: `workspace_id`, `tenant_id`, `name`, `scope_json`, `status`.

---

## Memory entities

### memory_namespaces
- Purpose: governable memory partitions.
- Fields: `memory_namespace_id`, `tenant_id`, `agent_id`, `workspace_id`, `conversation_id`, `namespace_type`, `classification`, `retention_policy`, `status`.
- Constraints: uniqueness by tenant + namespace qualifiers.

### memory_entries
- Purpose: memory records (episodic/semantic/tool/workflow).
- Fields: `memory_entry_id`, `tenant_id`, `memory_namespace_id`, `entry_type`, `content`, `metadata_json`, `provenance_json`, `expires_at`.

### memory_access_events
- Purpose: immutable read/write access trail.
- Fields: `event_id`, `tenant_id`, `memory_namespace_id`, `agent_id`, `action`, `decision_id`, `trace_id`, `created_at`.

---

## Tools/models/usage entities

### tool_registrations
- Purpose: canonical tool catalog entries.
- Fields: `tool_registration_id`, `tool_name`, `version`, `schema_json`, `status`.

### tool_permissions
- Purpose: per-tenant/per-agent/per-workflow tool grants.
- Fields: `tool_permission_id`, `tenant_id`, `agent_id`, `tool_name`, `workflow_scope_id`, `effect`, `status`.
- Constraints: deny-by-default, unique scope tuple.

### tool_invocations
- Purpose: invocation audit + attribution.
- Fields: `tool_invocation_id`, `tenant_id`, `agent_id`, `tool_name`, `decision_id`, `graph_run_id`, `session_id`, `conversation_id`, `trace_id`, `status`, `result_ref`.

### model_registrations
- Purpose: model catalog metadata.
- Fields: `model_registration_id`, `provider`, `model_name`, `capabilities_json`, `status`.

### model_permissions
- Purpose: tenant/agent/model allow rules.
- Fields: `model_permission_id`, `tenant_id`, `agent_id`, `model_registration_id`, `effect`, `status`.

### model_invocations
- Purpose: attributed model call records.
- Fields: `model_invocation_id`, `tenant_id`, `agent_id`, `model_registration_id`, `decision_id`, `token_usage_json`, `cost`, `trace_id`.

### usage_records
- Purpose: normalized usage billing/limits feed.
- Fields: `usage_record_id`, `tenant_id`, `agent_id`, `resource_type`, `resource_id`, `quantity`, `unit`, `cost`, `occurred_at`, `trace_id`.

---

## Decisions and audit entities

### decision_events
- Purpose: canonical allow/deny decision records.
- Fields: `decision_id`, `tenant_id`, `agent_id`, `sponsor_subject_id`, `request_actor`, `action`, `target_resource`, `required_capability`, `applicable_policies_json`, `result`, `reason`, `trace_id`, `created_at`.
- Constraints: append-only.

### audit_events
- Purpose: broad immutable operations/events.
- Fields: `audit_event_id`, `tenant_id`, `agent_id`, `event_type`, `resource_type`, `resource_id`, `decision_id`, `trace_id`, `payload_json`, `created_at`.
- Indexes: (`tenant_id`, `event_type`, `created_at`).

---

## Scheduling entities

### schedule_definitions
- Purpose: tenant-owned schedule configs.
- Fields: `schedule_definition_id`, `tenant_id`, `agent_id`, `flow_binding_id`, `cron_expr`, `timezone`, `status`.

### schedule_runs
- Purpose: execution record for schedules.
- Fields: `schedule_run_id`, `tenant_id`, `schedule_definition_id`, `agent_id`, `graph_run_id`, `decision_id`, `status`, `trace_id`, `started_at`, `ended_at`.

---

## Lifecycle and tenancy rules summary

1. Cross-tenant references prohibited by FK + application guards.
2. All execution records must include `tenant_id` + `agent_id` + `trace_id`.
3. Decision record required for any side-effecting action.
4. Agent lifecycle state gates execution (`active` required unless policy exception).
5. Suspension/revocation produces immediate deny outcomes.

