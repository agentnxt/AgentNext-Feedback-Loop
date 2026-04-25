BEGIN;

DROP TABLE IF EXISTS usage_records;
DROP TABLE IF EXISTS audit_events;
DROP TABLE IF EXISTS decision_events;
DROP TABLE IF EXISTS channel_bindings;
DROP TABLE IF EXISTS tool_permissions;
DROP TABLE IF EXISTS memory_entries;
DROP TABLE IF EXISTS memory_namespaces;
DROP TABLE IF EXISTS flow_bindings;
DROP TABLE IF EXISTS flow_definitions;
DROP TABLE IF EXISTS graph_runs;
DROP TABLE IF EXISTS graph_versions;
DROP TABLE IF EXISTS graph_definitions;
DROP TABLE IF EXISTS policy_bindings;
DROP TABLE IF EXISTS policies;
DROP TABLE IF EXISTS agent_identities;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS sponsors;
DROP TABLE IF EXISTS tenant_members;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS tenants;

COMMIT;
