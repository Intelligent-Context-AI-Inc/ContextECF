# ContextECF Architecture Overview

ContextECF is an infrastructure layer that assembles governed enterprise context across systems and delivers it through deterministic APIs. This document describes the deployment architecture, service model, and provider abstractions that enable ContextECF to run on-premise, in AWS, GCP, Azure, or in hybrid configurations.

---

## Deployment Planes

ContextECF separates concerns into three planes:

**Control Plane**
- Tenant administration, capability registry, policy management
- API surfaces and operational visibility
- Managed by ContextECF (SaaS) or by the customer (on-prem)

**Data Plane**
- Connectors ingest signals from enterprise systems, normalize them, and write to the Context Ledger
- Serves context retrieval workloads (search, context queries, briefs, synthesis)

**Customer-Owned Plane**
- Optional integration boundary for BYO storage or BYO-LLM
- Customer retains control over storage or compute where required by policy

## Deployment Topologies

### 1. Multi-Tenant SaaS (Shared Services)

All tenants share the same service fleet with cryptographic tenant isolation (RLS, JWT binding, ACL fail-closed). Best for SMB and mid-market.

### 2. Single-Tenant Dedicated

Per-tenant service stack for enterprises with strict isolation requirements. Stronger isolation, higher operational overhead.

### 3. Hybrid (Shared Control + Per-Tenant Data)

Control plane is shared; each tenant gets a dedicated data plane. Balances isolation with operational efficiency.

### 4. On-Premises / Private Cloud

Everything runs inside the customer's infrastructure. Connector runners and event bus are local. License-based entitlements replace marketplace billing.

## Two-Database Architecture

| Plane | What It Stores | Ownership |
|-------|---------------|-----------|
| **Control Plane DB** | Tenants, users, connectors, marketplace entitlements, audit logs | ContextECF-managed |
| **Context Data Plane DB** | Normalized Context Events (NCEs), episodes, context pods, golden IDs, drift signals, feedback | Customer-owned |

Both databases enforce Row-Level Security (RLS) with `set_config('app.tenant_id', ...)` bound to the authenticated JWT. No query can access data outside its tenant boundary.

## Service Architecture

All 36 services follow the same pattern:

- **Fastify v5.7+** HTTP framework
- **JWT authentication** with tenant binding
- **Zod schema validation** on all inputs/outputs
- **Health probes**: `/health/live` (liveness) and `/health/ready` (readiness with dependency checks)
- **Graceful shutdown** with 25-second force-exit timeout
- **Structured JSON logging** (no PII logged)
- **OpenTelemetry instrumentation** for distributed tracing

## Provider Abstraction

ContextECF uses provider abstractions for cloud-agnostic deployment:

| Capability | SaaS Provider | On-Prem Provider |
|-----------|---------------|------------------|
| Secrets | GCP Secret Manager / AWS Secrets Manager | Local filesystem |
| Events | GCP Pub/Sub / AWS SNS+SQS | Local in-process bus |
| Storage | GCS / S3 | Local filesystem |
| Entitlements | Marketplace billing APIs | JWS license file |

The same application code runs in all environments — only the provider configuration changes.
