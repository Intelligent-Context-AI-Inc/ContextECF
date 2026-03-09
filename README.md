# ContextECF

## Enterprise Context Fabric for AI Systems

ContextECF is an infrastructure platform that assembles enterprise context across systems and delivers it through deterministic APIs.

It enables AI systems, applications, and decision-makers to access the right context at the right moment.

---

## The Problem

Enterprise knowledge is fragmented.

Critical information lives across dozens of systems: CRM, messaging platforms, email, documents, tickets, code repositories, and analytics platforms.

Every AI assistant or application must repeatedly search these systems to reconstruct context. This leads to:

- Incomplete answers
- Hallucinations
- High compute cost
- Slow response times

---

## The Solution

ContextECF introduces a new architectural layer: **The Enterprise Context Fabric**.

Instead of searching systems for information on demand, ContextECF continuously assembles relevant context in advance. Applications retrieve ready-to-use context packages rather than raw data.

---

## Architecture Overview

ContextECF operates as a context infrastructure layer between enterprise systems and applications.

```
Enterprise Systems
CRM | Slack | Email | Docs | Tickets | Code | Meetings
         ↓
  Signal Ingestion
         ↓
  Context Assembly Engine
         ↓
  Context Ledger
         ↓
  Context APIs
         ↓
  Applications / AI Agents
```

### Services (36 microservices)

| Category | Services |
|----------|----------|
| **Core** | API Gateway, ECL Writer, Auth, Directory, Identity |
| **Intelligence** | Episodes, Context Pods, Drift Detection, Quality Scoring, Insight Tags |
| **Search & Retrieval** | Enterprise Ambient Search, Memory API, Prediction |
| **Integration** | Connector Gateway, Salesforce, Gmail, Calendar connectors |
| **Synthesis** | BYO-LLM Adapter, Synthesis Worker |
| **Operations** | Audit, Policy, ACL, Observability, Schema Registry |
| **Billing** | Marketplace (GCP/AWS/Azure), Stripe Billing, Entitlements |
| **Lifecycle** | Provisioning, Tenant Lifecycle, Tenant Mapping |

---

## Key Capabilities

### Context Assembly

Combine signals across enterprise systems into structured context.

### Deterministic Context APIs

Retrieve context using predictable APIs designed for AI and applications.

### Context Synthesis

Generate briefs, summaries, and insight signals.

### Policy-Governed Context

Security and access policies are enforced across context objects.

### Time-to-Context Reduction

ContextECF dramatically reduces Time-to-Context, enabling faster decision making and AI responses.

---

## Deployment Options

ContextECF can run in multiple environments.

| Deployment | Description |
|------------|-------------|
| **On-Premise** | Fully contained within your infrastructure |
| **AWS** | Deploy within your VPC |
| **GCP** | Deploy within your GCP project |
| **Azure** | Deploy within your Azure tenant |
| **Hybrid** | Combine on-prem and cloud environments |

- **Phase 1**: Docker Compose (available now)
- **Phase 2**: Helm chart for Kubernetes

See the [On-Prem Deployment Guide](docs/on-prem-guide.md) for full instructions.

---

## Quick Start

```bash
git clone https://github.com/Intelligent-Context-AI-Inc/ContextECF.git
cd ContextECF/starter

export REGISTRY_TOKEN=<token>
./install.sh
```

### Prerequisites

- Docker Engine 20.10+ and Docker Compose v2+
- 8 GB RAM minimum, 10 GB free disk
- Trial credentials (sign up at [timetocontext.co/trial](https://timetocontext.co/trial))

### Verify

```bash
# Check service status
./fabric status

# Run health checks
./fabric verify

# View the API
curl http://localhost:8080/health/ready
```

### Endpoints

| Service | URL |
|---------|-----|
| API Gateway | http://localhost:8080 |
| Admin Console | http://localhost:3000 |

---

## Fabric CLI

The `fabric` CLI manages your ContextECF environment:

```bash
./fabric up              # Start all services
./fabric down            # Stop all services
./fabric status          # Show service status
./fabric logs            # View logs
./fabric logs api-gateway # View specific service logs
./fabric verify          # Run health checks
./fabric doctor          # Check system prerequisites
./fabric request-license # Generate trial license request
```

---

## Trial License

ContextECF on-prem requires a license for write operations. To get a trial license:

1. Run `./fabric request-license`
2. Send the generated `trial_request_*.json` to ash@intelligentcontext.ai
3. Place the received `license.jwt` in `starter/manifests/`
4. Restart: `./fabric down && ./fabric up`

**Data access guarantee**: Read and export access to your data is **never** blocked, even after license expiry. You always own your data.

---

## Key APIs

| Endpoint | Description |
|----------|-------------|
| `POST /v1/nce` | Ingest Normalized Context Event |
| `POST /v1/context/query` | Query context capsules |
| `POST /v1/search` | Enterprise Ambient Search |
| `GET /v1/accounts/:id/brief` | Account Brief |
| `GET /v1/drift/signals` | Context Drift Signals |
| `GET /v1/myooo/status` | Continuity Status |
| `POST /v1/synthesis/run` | BYO-LLM Synthesis |
| `GET /health/live` | Liveness probe |
| `GET /health/ready` | Readiness probe |

---

## Example Use Cases

ContextECF enables a wide range of enterprise capabilities.

| Use Case | Description |
|----------|-------------|
| **AI Copilots** | Provide copilots with rich enterprise context |
| **Relationship Intelligence** | Understand the strength and history of relationships across an organization |
| **Meeting Preparation** | Generate instant context briefs before meetings |
| **Enterprise Search** | Search across context rather than across systems |
| **Decision Intelligence** | Combine signals across systems to generate insights |

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | TypeScript (ES2022) |
| Runtime | Node.js 20 LTS |
| Framework | Fastify v5.7+ |
| Database | PostgreSQL 15 (with RLS) |
| Cache | Redis 7 |
| Search | PostgreSQL FTS + pg_trgm |
| Containers | Docker / Kubernetes |
| Validation | Zod schemas |
| Telemetry | OpenTelemetry |

---

## Security

ContextECF is built with security as a foundational property:

- **140 tenant isolation tests** covering every attack vector (JWT extraction, RLS, cache-key prefixing, ACL fail-closed, SSRF guards)
- **Row-Level Security (RLS)** enforced at the database layer — tenant data is cryptographically isolated
- **JWT-only tenant identification** — tenant_id is never accepted from request headers or body
- **Fail-closed ACL** — access control errors result in denial, never implicit access
- **Immutable audit log** — all privileged operations are recorded
- **Zero critical/high vulnerabilities** in the dependency tree
- **SBOM included** (CycloneDX format) for supply chain transparency

---

## Documentation

| Document | Description |
|----------|-------------|
| [On-Prem Deployment Guide](docs/on-prem-guide.md) | Full installation and configuration |
| [Architecture Overview](docs/architecture.md) | Deployment topologies and data flow |
| [Helm Chart Guide](docs/helm-guide.md) | Kubernetes deployment with Helm |
| [API Overview](docs/api-overview.md) | API surface and authentication |
| [Category Definition](docs/context-engineering/category-definition.md) | What is an Enterprise Context Fabric |
| [Context Engineering Manifesto](docs/context-engineering/context-engineering-manifesto.md) | The missing layer in enterprise AI |

---

## System Requirements

### Minimum (Trial / Development)

| Resource | Requirement |
|----------|-------------|
| CPU | 2 cores |
| RAM | 8 GB |
| Disk | 10 GB free |
| Docker | 20.10+ |
| Compose | v2+ |

### Recommended (Production)

| Resource | Requirement |
|----------|-------------|
| CPU | 4+ cores |
| RAM | 16+ GB |
| Disk | 50+ GB SSD |
| PostgreSQL | 15+ (external recommended) |
| Redis | 7+ (external recommended) |
| OIDC Provider | Okta, Azure AD, Keycloak, etc. |

---

## Why ContextECF Exists

Large language models are powerful. But they lack context.

ContextECF provides the infrastructure layer that gives AI systems access to enterprise context safely and efficiently.

---

## Support

- **Contact**: ash@intelligentcontext.ai
- **Phone**: (916) 753-7432
- **Website**: [timetocontext.co](https://timetocontext.co)

---

## License

Copyright (c) 2024-2026 Intelligent Context AI, Inc. All Rights Reserved.

See [LICENSE](LICENSE) for full terms. ContextECF is proprietary software available through marketplace subscriptions and on-premises licensing agreements.
