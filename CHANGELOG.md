# Changelog

All notable changes to ContextECF RPaaS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- PHASE_STATUS.md — Tracks completion state of all 9 platform phases with evidence links
- Azure Marketplace integration (Phase 10) — entitlement handler, webhook routes, Blob Storage; gated behind `AZURE_MARKETPLACE_ENABLED` feature flag (Preview)
- **Production Resilience Hardening** (March 2026) — 10-phase production hardening pass:
  - SBOM generation: `npm run sbom` for supply chain transparency (CycloneDX format)
  - Release evidence: `npm run release:evidence` with explicit PASS/FAIL/NOT_RUN/COULD_NOT_EXECUTE states
  - Configuration validation: `npm run config:check` for pre-deploy env var diagnostics
  - Tenant boundary gate: `npm run test:tenant-boundary` as canonical Phase 0 command
  - Post-deploy smoke verification wired into CI deploy workflows
  - Rollback verification script: `scripts/rollback-verify.sh` with retry logic
  - Production runbooks: deploy, rollback, incident-response, smoke-validation, configuration-and-secrets
  - Operator first-response guide: `docs/ops/OPERATOR_FIRST_RESPONSE.md`
  - Health endpoint contract: `docs/ops/HEALTH_CONTRACT.md`
  - Tenant isolation certification: `docs/ops/TENANT_ISOLATION_CERTIFICATION.md`
  - See `docs/production-resilience-hardening-report.md` for complete evidence

### Changed

- R4 Guarded Execution connectors (Gmail, Calendar, Internal) are marked **Preview** — simulated API calls only; real OAuth-backed API integration planned for v1.2
- R4 `checkRateLimit` now defaults to DENY when no config exists (consistent with DEFAULT-DENY posture)
- R4 validate/execute/queue/rollback endpoints now check per-action-type feature flags in addition to `execution_enabled`

### Fixed

- **P0** Auth service: `GDES_SERVICE_URL` now injected in cloudbuild.yaml deploy step (was missing — JIT provisioning and SCIM would silently fall back to lowest-privilege role)
- **P0** API Gateway: `CAPSULE_SERVICE_URL` now injected in cloudbuild.yaml deploy step (was missing — `POST /v1/capsules` would fail with connection refused in Cloud Run)
- Signal-engine PORT aligned to 8090 across cloudbuild.yaml and docker-compose.yml
- Search.tsx: Replaced raw `sourceType` ternary with `SOURCE_TYPE_LABELS` lookup map with safe fallback

### Security

---

## [1.1.0] - 2026-02-28

### Added

#### Use Case Completion (February 2026)

- **Customer Support Intelligence** - Complete backend and frontend implementation
  - Support case service and routes
  - Support case brief generation
  - Episode querying for SUPPORT_CASE episodes
  - Admin console pages (SupportCases, SupportCaseBrief)
  - API endpoints: `/api/v1/support/cases`, `/api/v1/briefs/support-case/:id`, `/api/v1/support/cases/search`

- **CodeLedger Admin UI** - Complete backend and frontend implementation
  - CodeLedger admin routes
  - Session listing and detail retrieval
  - Statistics endpoint
  - Admin console pages (CodeLedger dashboard)
  - API endpoints: `/api/v1/codeledger/sessions`, `/api/v1/codeledger/sessions/:id`, `/api/v1/codeledger/stats`

**Result:** 6/6 use cases complete (100% coverage)

#### Connector Platform Expansion

- **13 MCP Connectors** - All production-ready
  - Microsoft 365 (Exchange, Teams, SharePoint, Calendar)
  - Slack (Channels, DMs, Threads)
  - Salesforce (Accounts, Contacts, Opportunities, Tasks, Events)
  - Google Workspace (Gmail, Calendar, Drive)
  - HubSpot (Contacts, Companies, Deals, Engagements)
  - Zoom (Meetings, Webinars, Recordings)
  - Asana (Tasks, Projects, Teams)
  - Smartsheet (Sheets, Rows, Attachments)
  - ServiceNow (Incidents, Tasks, Change Requests)
  - Workday (Workers, Organizations, Time Off)
  - Google Hangouts (Messages, Spaces via Google Chat API)
  - Jira (Issues, Comments)
  - Zendesk (Tickets, Comments)

- **Connector Certification Framework**
  - Automated certification checklist (`run-connector-certification.ts`)
  - GA readiness scoring (≥90% required)
  - Evidence collection from codebase analysis
  - Coverage matrix and fallback path documentation

#### R4 Advisory Execution Framework

- **Pattern Library (Epic 14)**
  - Pattern matching engine with confidence scoring
  - Pattern families and tenant-scoped pattern management
  - Match history tracking

- **Action Proposals (Epic 15)**
  - User-facing proposals with explicit state machine (GENERATED → PENDING → APPROVED)
  - Evidence collection and parameter validation
  - Proposal lifecycle management

- **Guarded Execution (Epic 16)**
  - Multi-stage validation pipeline (rate-limit, permission, precondition, scope)
  - Connector adapters: Gmail, Calendar, Internal
  - Rollback support and scope validation
  - User-bound credentials (OAuth tokens per-user)

- **Outcome Feedback Loop (Epic 17)**
  - Outcome observations and correlations
  - Confidence updates bounded to 0.1-0.95
  - Learning restrictions enforced

- **Audit Logging (Epic 18)**
  - Immutable audit events for all privileged operations
  - Compliance reports and audit trails

- **Feature Flags & Admin Controls (Epic 19)**
  - DEFAULT-DENY architecture (all execution features disabled by default)
  - Hierarchical feature dependencies
  - Rate limiting per user/tenant

**API Endpoints:**

- `/v1/r4/flags/*` - Feature flag management
- `/v1/r4/audit/*` - Audit log access
- `/v1/r4/patterns/*` - Pattern library API
- `/v1/r4/proposals/*` - Proposal lifecycle API
- `/v1/r4/execution/*` - Execution management API
- `/v1/r4/outcomes/*` - Outcome feedback API

**Database Migrations:**

- `053_r4_feature_flags.ts` - Feature flags and rate limit tables
- `054_r4_action_patterns.ts` - Pattern library and match history
- `055_r4_action_proposals.ts` - Proposals, parameters, evidence, transitions
- `056_r4_guarded_execution.ts` - Execution requests, results, rollbacks, scopes
- `057_r4_outcome_feedback.ts` - Observations, correlations, confidence updates

**Critical Constraints:**

- DEFAULT-DENY: All execution features disabled by default
- Human-in-the-loop: Proposals require explicit approval before execution
- Fail-closed validation: 4-stage validation pipeline
- User-bound credentials: OAuth tokens per-user, never global service tokens
- Single-step execution: No chained or multi-step autonomous actions
- Bounded confidence: Learning can only update 0.1 ≤ confidence ≤ 0.95

### Changed

- Standardized error response handling across all services using `createErrorHandler()` and `createNotFoundHandler()`
- Adopted `sendInvalidRequest()`, `sendForbidden()`, `sendNotFound()`, and `buildErrorResponse()` helpers from `@contextecf/common`

### Fixed

- Zod validation errors no longer leak schema internals in HTTP responses
- PL/pgSQL functions now include `SET search_path = public` to prevent search_path injection
- OAuth state parameter validation uses HMAC-SHA256 with `timingSafeEqual`

### Security

- Codified V1–V12 code review findings into CLAUDE.md as permanent guardrails
- Added graceful shutdown pattern with mandatory 25-second force-exit timeout to all services
- Hardened Zod error handling to never serialize `.error.message` or `.error.issues` to clients
- All catch blocks now use `buildErrorResponse()` instead of raw error details

---

## [1.0.0] - 2026-01-30

First General Availability release for AWS and GCP Marketplace submission.

### Added

#### Enterprise Security & Scale Hardening

- Connection pool tenant isolation tests (50k user deployment ready)
- Enterprise-grade tenant context isolation
- Pool leakage prevention for multi-tenant deployments
- Chaos tenant isolation test suite

#### Phase 9: BYO-LLM Synthesis (Optional)

Customer-hosted LLM integration for AI-powered synthesis capabilities.

**Phase 9.1 - Synthesis Service Foundation**

- Synthesis service with provider interface
- Tenant configuration schema for synthesis settings
- NONE provider (default, synthesis disabled)
- Provider registry for extensibility

**Phase 9.2 - Context Capsule Builder**

- Deterministic capsule building (no LLM, no randomness)
- Policy-based content redaction
- Capsule hashing for audit matching
- Provenance chain from capsule to source NCEs
- Redaction modes: strict, standard, verbose
- Size controls with truncation

**Phase 9.3 - Customer Endpoint Provider**

- CUSTOMER_ENDPOINT provider for BYO-LLM
- SSRF protection (blocks private IPs, cloud metadata)
- Endpoint allowlist with admin approval
- API key authentication via Secret Manager
- Configurable timeouts (5s - 120s)

**Phase 9.4 - Audit & Invocation Receipts**

- Invocation receipts for every synthesis attempt
- Receipt storage (NOT content storage by default)
- Status tracking: SUCCESS, FAILED, TIMEOUT, BLOCKED
- Optional output storage as NCEs
- Capsule hash for audit trail matching

**Phase 9.5 - Synthesis API & UI Integration**

- Synthesis orchestrator service
- REST API endpoints via API gateway
- Salesforce Lightning Web Component
- Admin console configuration page
- Comprehensive BYO-LLM documentation

#### CI/CD & Release Infrastructure

- GitHub Actions release workflow with tag-triggered builds
- Automated Docker image publishing to container registry
- Release checklist script for pre-release validation
- Version bump script for post-release workflow
- Phase 0 security gate automation in CI

### Security

- SSRF protection blocks private IP ranges and cloud metadata endpoints
- Endpoint allowlist requires explicit admin approval
- API keys stored in Google Secret Manager only (never plaintext)
- Capsule hashing for deterministic audit matching
- All synthesis attempts create audit receipts
- Connection pool tenant context isolation (enterprise hardening)

### Documentation

- BYO-LLM Synthesis guide (`docs/marketplace/BYO-LLM-Synthesis.md`)
- API reference for synthesis endpoints
- Salesforce LWC installation guide
- Admin console configuration walkthrough
- Release process documentation

### Important Notes

**Synthesis is OPTIONAL** - GA v1 works fully without any LLM.

**Non-Negotiable Constraints:**

- LLM inference occurs in CUSTOMER environment, not ContextECF
- ContextECF provides context only; customer model generates text
- All outputs require human review before use
- No autonomous actions, email sending, or CRM write-backs
- No impersonation of any kind
- All outputs marked as AI-generated

---

## [0.1.0] - 2026-01-11

### Added

#### Phase 0: Repository & Documentation

- Monorepo structure with packages/, services/, infra/, docs/
- Canonical specification as single source of truth
- Authority hierarchy documentation
- ADR structure for architectural decisions
- Core TypeScript types for all domain entities
- Platform constants and configuration

#### Phase 1: Platform Spine

- Authentication service with JWT validation
- Tenant context extraction from JWT (never from request)
- NCE (Normalized Context Event) schema with Zod validation
- ECL (Enterprise Context Ledger) append-only writer
- Audit logging service via Pub/Sub
- Redis-based rate limiting with sliding window
- API Gateway with health endpoints

#### Phase 2: GCP Marketplace Integration

- Marketplace entitlement webhook handler
- Tenant provisioning on entitlement activation
- Plan-to-policy mapping (SMB vs Enterprise)
- Onboarding flow for data plane setup
- Support for customer-owned GCP/AWS data planes

#### Phase 3: Salesforce Continuity

- Connector framework with OAuth2 support
- Salesforce connector with incremental sync
- NCE normalization for Salesforce objects
- Golden ID identity resolution
- Account brief API and context assembly
- Stakeholder map generation

#### Phase 4: Ambient Search

- PostgreSQL full-text search with pg_trgm
- Search index service
- Structured query syntax parser
- Episode formation and lifecycle
- Permission-aware search filtering

#### Phase 5: myooo & Drift Detection

- Drift detection rules engine
- Engagement gap detection
- myooo continuity triggers (OOO, latency, saturation)
- Re-entry brief generation
- Policy engine integration

### Security

- Strict tenant isolation (tenant_id from JWT only)
- Append-only ECL with database triggers
- Rate limiting per tenant plan
- Audit logging for all operations
- Secret management via Google Secret Manager

### Infrastructure

- Cloud Run for all services
- PostgreSQL 15 (Cloud SQL) for databases
- Redis (Memorystore) for caching
- Pub/Sub for async messaging
- Terraform modules for infrastructure

---

## Version History

| Version | Date       | Description                                          |
| ------- | ---------- | ---------------------------------------------------- |
| 1.1.0   | 2026-02-28 | Use case completion, 13 connectors, R4 Advisory, security hardening |
| 1.0.0   | 2026-01-30 | GA release for AWS/GCP Marketplace                   |
| 0.1.0   | 2026-01-11 | Initial release with Phases 0-5                      |

---

## Upgrade Notes

### Upgrading to 1.0.0

1. Run all database migrations
2. Deploy updated services
3. Verify Phase 0 security gates pass
4. (Optional) Configure BYO-LLM synthesis

### BYO-LLM Synthesis Setup

Phase 9 synthesis is entirely optional. No changes required if not using synthesis.

If enabling synthesis:

1. Deploy the synthesis service
2. Run migration `016_synthesis_config.ts`
3. Configure synthesis in Admin Console
4. Set up your LLM endpoint
5. Add endpoint to allowlist
6. Enable for users

### New Database Tables (v1.0.0)

- `synthesis_config` - Tenant synthesis configuration
- `synthesis_invocations` - Audit receipts for synthesis calls
- `synthesis_allowlist` - Approved endpoints per tenant

### New Environment Variables (v1.0.0)

- `SYNTHESIS_SERVICE_URL` - Internal URL for synthesis service
- `SECRET_MANAGER_PROJECT` - GCP project for secrets
