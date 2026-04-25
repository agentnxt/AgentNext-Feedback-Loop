BEGIN;

-- Phase-1 foundation migration for Autonomyx multi-tenant governance.
-- Backward-compatible: does not alter existing sessions/messages tables in hermes_state.py.

CREATE TABLE IF NOT EXISTS tenants (
    tenant_id TEXT PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    metadata_json TEXT,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,
    subject_type TEXT NOT NULL,
    subject_ref TEXT NOT NULL,
    email TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(subject_type, subject_ref)
);

CREATE TABLE IF NOT EXISTS tenant_members (
    tenant_member_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    membership_state TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, user_id)
);

CREATE TABLE IF NOT EXISTS sponsors (
    sponsor_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    sponsor_subject_id TEXT NOT NULL,
    sponsor_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    metadata_json TEXT,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, sponsor_subject_id, sponsor_type)
);

CREATE TABLE IF NOT EXISTS agents (
    agent_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    description TEXT,
    agent_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, agent_id)
);

CREATE TABLE IF NOT EXISTS agent_identities (
    agent_identity_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    sponsor_subject_id TEXT NOT NULL,
    sponsor_type TEXT NOT NULL,
    lifecycle_state TEXT NOT NULL,
    trust_level TEXT,
    risk_tier TEXT,
    auth_profile_id TEXT,
    execution_policy_id TEXT,
    budget_policy_id TEXT,
    memory_policy_id TEXT,
    graph_policy_id TEXT,
    tool_policy_id TEXT,
    channel_policy_id TEXT,
    approved_at REAL,
    activated_at REAL,
    suspended_at REAL,
    revoked_at REAL,
    expires_at REAL,
    provenance_json TEXT,
    audit_json TEXT,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, agent_id)
);

CREATE TABLE IF NOT EXISTS policies (
    policy_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    policy_type TEXT NOT NULL,
    version TEXT NOT NULL,
    document_json TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, policy_type, version)
);

CREATE TABLE IF NOT EXISTS policy_bindings (
    policy_binding_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    binding_target_type TEXT NOT NULL,
    binding_target_id TEXT NOT NULL,
    policy_id TEXT NOT NULL REFERENCES policies(policy_id) ON DELETE CASCADE,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, binding_target_type, binding_target_id, policy_id)
);

CREATE TABLE IF NOT EXISTS graph_definitions (
    graph_definition_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    owner_agent_id TEXT,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, name)
);

CREATE TABLE IF NOT EXISTS graph_versions (
    graph_version_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    graph_definition_id TEXT NOT NULL REFERENCES graph_definitions(graph_definition_id) ON DELETE CASCADE,
    version TEXT NOT NULL,
    spec_json TEXT NOT NULL,
    checksum TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at REAL NOT NULL,
    UNIQUE(tenant_id, graph_definition_id, version)
);

CREATE TABLE IF NOT EXISTS graph_runs (
    graph_run_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    graph_version_id TEXT NOT NULL REFERENCES graph_versions(graph_version_id) ON DELETE CASCADE,
    agent_id TEXT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    sponsor_subject_id TEXT,
    status TEXT NOT NULL,
    state_json TEXT,
    trace_id TEXT NOT NULL,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS flow_definitions (
    flow_definition_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    source_format TEXT NOT NULL,
    source_json TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, name)
);

CREATE TABLE IF NOT EXISTS flow_bindings (
    flow_binding_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    flow_definition_id TEXT NOT NULL REFERENCES flow_definitions(flow_definition_id) ON DELETE CASCADE,
    binding_type TEXT NOT NULL,
    binding_target_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS memory_namespaces (
    memory_namespace_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT REFERENCES agents(agent_id) ON DELETE CASCADE,
    workspace_id TEXT,
    conversation_id TEXT,
    namespace_type TEXT NOT NULL,
    classification TEXT NOT NULL DEFAULT 'internal',
    retention_policy_json TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS memory_entries (
    memory_entry_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    memory_namespace_id TEXT NOT NULL REFERENCES memory_namespaces(memory_namespace_id) ON DELETE CASCADE,
    entry_type TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata_json TEXT,
    provenance_json TEXT,
    expires_at REAL,
    created_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS tool_permissions (
    tool_permission_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL,
    workflow_scope_id TEXT,
    effect TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, agent_id, tool_name, workflow_scope_id)
);

CREATE TABLE IF NOT EXISTS channel_bindings (
    channel_binding_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    channel_type TEXT NOT NULL,
    endpoint_ref TEXT NOT NULL,
    agent_id TEXT NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
    flow_definition_id TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    UNIQUE(tenant_id, channel_type, endpoint_ref, agent_id)
);

CREATE TABLE IF NOT EXISTS decision_events (
    decision_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT,
    sponsor_subject_id TEXT,
    request_actor TEXT,
    action TEXT NOT NULL,
    target_resource TEXT,
    required_capability TEXT,
    applicable_policies_json TEXT,
    result TEXT NOT NULL,
    reason TEXT,
    trace_id TEXT NOT NULL,
    created_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_events (
    audit_event_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT,
    event_type TEXT NOT NULL,
    resource_type TEXT,
    resource_id TEXT,
    decision_id TEXT,
    trace_id TEXT,
    payload_json TEXT,
    created_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS usage_records (
    usage_record_id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    agent_id TEXT,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    quantity REAL NOT NULL,
    unit TEXT NOT NULL,
    cost REAL,
    trace_id TEXT,
    occurred_at REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tenant_members_tenant ON tenant_members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agents_tenant ON agents(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_agent_identities_tenant_agent ON agent_identities(tenant_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_policies_tenant_type ON policies(tenant_id, policy_type, status);
CREATE INDEX IF NOT EXISTS idx_graph_runs_tenant_agent ON graph_runs(tenant_id, agent_id, created_at);
CREATE INDEX IF NOT EXISTS idx_memory_ns_tenant_agent ON memory_namespaces(tenant_id, agent_id, namespace_type);
CREATE INDEX IF NOT EXISTS idx_memory_entries_tenant_ns ON memory_entries(tenant_id, memory_namespace_id, created_at);
CREATE INDEX IF NOT EXISTS idx_tool_permissions_scope ON tool_permissions(tenant_id, agent_id, tool_name, status);
CREATE INDEX IF NOT EXISTS idx_channel_bindings_tenant ON channel_bindings(tenant_id, agent_id, channel_type, status);
CREATE INDEX IF NOT EXISTS idx_decisions_tenant_agent ON decision_events(tenant_id, agent_id, created_at);
CREATE INDEX IF NOT EXISTS idx_decisions_trace ON decision_events(trace_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_tenant_type ON audit_events(tenant_id, event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_usage_tenant_agent ON usage_records(tenant_id, agent_id, occurred_at);

COMMIT;
