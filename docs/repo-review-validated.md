# Repo Review: What Users Can Do with This Project Today

> **Status**: Validated against repository contents (v1.0.0-rc1)
> **Date**: 2026-03-09

This repository was reviewed as a product and deployment package (not a full application source repo). Most contents are docs, deployment artifacts, Helm templates, and starter automation scripts.

---

## 1) What ContextECF Is For

Users can use ContextECF as an Enterprise Context Fabric — an infrastructure layer that assembles governed enterprise context across systems (CRM, messaging, documents, operations tools) and delivers it through deterministic APIs for AI systems and enterprise applications.

---

## 2) What End Users / Customer Teams Can Do

### A) Deploy It (Self-Hosted or Cloud-Marketplace Model)

- Deploy on-prem/self-hosted with Docker Compose now (Phase 1), and Helm/Kubernetes as a Phase 2 path.
- Cloud marketplace deployment models (GCP/AWS, Azure preview) are referenced in docs but **no marketplace artifacts are included in this repo**; these are documentation claims only.

### B) Run the Starter Experience Quickly

- Use `starter/install.sh` for a one-command flow that performs prereq checks, validates registry credentials, generates `.env`, pulls images, starts services, and verifies health.
- Access API Gateway (port 8080) and Admin Console (port 3000) once running.

### C) Operate the Environment with CLI Commands

Users can manage the deployment via `./fabric`:

| Command | Description |
|---|---|
| `./fabric up` | Start all services (also runs verification and prints endpoints) |
| `./fabric down` | Stop all services |
| `./fabric pull` | Pull latest images |
| `./fabric status` | Show service status |
| `./fabric logs [service]` | View logs |
| `./fabric verify` | Run health checks |
| `./fabric doctor` | Check prerequisites |
| `./fabric request-license` | Generate trial license request |

### D) Generate and Apply Trial Licensing

- Generate a local trial request JSON via `./fabric request-license`.
- Email the file to licensing; place the received `license.jwt` in `starter/manifests/`.
- No data is transmitted automatically by the script.

### E) Use APIs for Ingestion, Retrieval, Search, Intelligence, and Synthesis

Core user-visible API capabilities (JWT/OIDC-based auth required, tenant binding):

| Endpoint | Description |
|---|---|
| `POST /v1/nce` | Ingest Normalized Context Events |
| `POST /v1/context/query` | Query context capsules |
| `POST /v1/search` | Enterprise Ambient Search |
| `GET /v1/accounts/:id/brief` | Account Briefs |
| `GET /v1/drift/signals` | Drift Signals |
| `GET /v1/myooo/status` | MyOOO Continuity Status |
| `POST /v1/synthesis/run` | BYO-LLM Synthesis |
| `GET /health/live`, `GET /health/ready` | Health probes |
| `GET /v1/license/status` | License status (on-prem) |

### F) Perform Production Ops

Production guide (`docs/on-prem-guide.md`) includes env prep, preflight checks, startup, migration, verification, upgrade, rollback approach, and backup/restore workflows.

### G) Deploy on Kubernetes with Security Controls

Helm workflow supports external DB/Redis, OIDC/license settings, secret references, autoscaling, and network policies. The Helm chart currently defines **7 services** (api-gateway, ecl-writer, auth, directory, entitlements, audit, policy).

---

## 3) What This Repo Does Not Provide Directly

- **No application source code**: No `.ts`, `.js`, `package.json`, or `tsconfig.json` files. Services are delivered as prebuilt container images from a private registry, orchestrated via Compose/Helm.
- **Starter Compose is a subset**: The starter `docker-compose.yml` runs ~10 services (api-gateway, auth, policy, entitlements, audit, connector-gateway, admin-console, postgres, redis, db-migrate), not the full 36 referenced in the README.
- **Starter runs in development mode**: `NODE_ENV=development` by default; the starter is a trial/evaluation environment, not production-ready as-is.

User activity in this repo is: deploy, configure, run, validate, and operate — not implement service logic.

---

## 4) Release Assets (GitHub)

The `v1.0.0-rc1` release on GitHub includes downloadable assets not tracked in the git tree:

| Asset | Size | Purpose |
|---|---|---|
| `contextecf-fabric-v1.0.0-rc1.zip` | ~14 KB | Packaged starter bundle (alternative to git clone) |
| `SHA256SUMS` | 99 bytes | Integrity verification for the zip |

These are **release artifacts** attached to the GitHub Release, not files committed in the repository. This is standard practice — the zip provides a download option for users who prefer not to clone.

---

## 5) Practical Summary by Persona

| Persona | What They Can Do |
|---|---|
| **Platform / Admin** | Install and run a local or production deployment, monitor health, inspect logs, manage license lifecycle, perform upgrades/backups |
| **Developer / Integration** | Authenticate with JWT/OIDC and integrate against ingestion/retrieval/search/synthesis APIs |
| **Security / Compliance** | Leverage tenant isolation model, RLS/JWT assumptions, and secrets/network policy patterns in Kubernetes |

---

## 6) Repository Inventory

**29 tracked files** across 5 categories:

| Category | Count | Contents |
|---|---|---|
| Documentation | 4 markdown files | Platform overview, API, architecture, deployment guides |
| Deployment Config | 11 YAML files | Docker Compose, Helm templates, environment templates |
| Starter Scripts | 5 bash scripts | Installation, verification, health, license, CLI |
| Manifests | 2 JSON files | Configuration and schema validation |
| Metadata | 3 files | README, CHANGELOG, LICENSE, .gitignore |

---

## Validation Notes

All claims verified against the actual repository contents at commit `c95f1e3` (tag `v1.0.0-rc1`). Key corrections from the original draft:

1. **Cloud marketplace**: Docs reference GCP/AWS/Azure but no marketplace artifacts exist in this repo.
2. **Service count discrepancy**: README references 36 microservices; starter Compose runs ~10; Helm chart defines 7.
3. **Release assets**: The `contextecf-fabric-v1.0.0-rc1.zip` and `SHA256SUMS` are GitHub Release assets, not missing files from the repo tree.
4. **Development mode**: Starter defaults to `NODE_ENV=development`; production use requires the on-prem guide workflow.
