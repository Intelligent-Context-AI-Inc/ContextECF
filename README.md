# ContextECF — Enterprise Relationship Intelligence Infrastructure

**ContextECF RPaaS** (Relationship Platform as a Service) provides enterprise relationship intelligence infrastructure that augments your CRM, creating and maintaining the **Enterprise Context Ledger (ECL)** — a new enterprise asset class.

ContextECF is **infrastructure, not an app**. It sits alongside your CRM, captures relationship signals from email, calendar, and meetings, and makes that context available to your teams and AI agents through a structured API.

---

## Why ContextECF

| Problem | ContextECF Solution |
|---------|---------------------|
| CRM data decays within weeks | Continuous, automated context capture |
| Relationship knowledge lives in people's heads | Enterprise Context Ledger — structured, queryable, auditable |
| AI agents lack organizational memory | Memory API provides context to any LLM |
| No single view of relationship health | Drift detection, episode formation, quality scoring |
| Vendor lock-in on relationship data | **You own your data** — always exportable, never locked |

## Core Principles

1. **CRM is never replaced** — ContextECF augments, never competes
2. **No autonomous outreach** — no impersonation, no scraping, no unsanctioned messages
3. **Customers own their data** — read and export access is never blocked, even after license expiry
4. **All intelligence is explainable** — no black-box scoring
5. **Tenant isolation is mandatory** — cryptographic enforcement at every layer

---

## Platform Architecture

```
                    ┌──────────────────────────────────┐
                    │         API Gateway (8080)        │
                    │   JWT Auth · Rate Limiting · ACL  │
                    └──────────┬───────────────────────┘
                               │
            ┌──────────────────┼──────────────────────┐
            │                  │                      │
     ┌──────▼──────┐   ┌──────▼──────┐   ┌───────────▼──────┐
     │  ECL Writer  │   │   Search    │   │   Memory API     │
     │ (Append-only)│   │  (Ambient)  │   │  (LLM Context)   │
     └──────┬──────┘   └──────┬──────┘   └───────────┬──────┘
            │                  │                      │
     ┌──────▼──────────────────▼──────────────────────▼──────┐
     │              Enterprise Context Ledger                 │
     │     PostgreSQL 15 · RLS · Tenant Isolation · Audit     │
     └───────────────────────────────────────────────────────┘
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

## Deployment Options

### On-Premises (Self-Hosted)

Deploy ContextECF inside your own infrastructure — data center, private VPC, or air-gapped environment. All data stays within your network boundary.

- **Phase 1**: Docker Compose (available now)
- **Phase 2**: Helm chart for Kubernetes

See the [On-Prem Deployment Guide](docs/on-prem-guide.md) for full instructions.

### Cloud Marketplace

Available on:
- **Google Cloud Marketplace** — Cloud Run + Cloud SQL + Memorystore
- **AWS Marketplace** — ECS/Fargate + RDS + ElastiCache
- **Azure Marketplace** — Preview (feature-gated)

---

## Quick Start (On-Prem Trial)

### Prerequisites

- Docker Engine 20.10+ and Docker Compose v2+
- 8 GB RAM minimum, 10 GB free disk
- Trial credentials (sign up at [timetocontext.co/trial](https://timetocontext.co/trial))

### Install

```bash
# 1. Clone or download the starter kit
git clone https://github.com/Intelligent-Context-AI-Inc/ContextECF.git
cd ContextECF/starter

# 2. Set your registry credentials (provided after trial signup)
export REGISTRY_TOKEN=<your-token>
export REGISTRY=<your-registry-url>

# 3. Run the one-command installer
./install.sh
```

The installer will:
- Verify your system meets minimum requirements
- Authenticate with the container registry
- Pull and start all required services
- Run health verification

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
| `POST /v1/nce` | Create Normalized Context Event |
| `POST /v1/context/query` | Query context capsules |
| `POST /v1/search` | Enterprise Ambient Search |
| `GET /v1/accounts/:id/brief` | Account Brief |
| `GET /v1/drift/signals` | Drift Signals |
| `GET /v1/myooo/status` | MyOOO Continuity Status |
| `POST /v1/synthesis/run` | BYO-LLM Synthesis |
| `GET /health/live` | Liveness probe |
| `GET /health/ready` | Readiness probe |

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

ContextECF is built with security as a foundational property, not an afterthought:

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

## Support

- **Trial support**: ash@intelligentcontext.ai
- **Licensing**: ash@intelligentcontext.ai
- **Website**: [timetocontext.co](https://timetocontext.co)

---

## License

Copyright (c) 2024-2026 Intelligent Context AI, Inc. All Rights Reserved.

See [LICENSE](LICENSE) for full terms. ContextECF is proprietary software available through marketplace subscriptions and on-premises licensing agreements.
