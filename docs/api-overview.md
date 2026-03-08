# ContextECF API Overview

## Authentication

All API requests require a valid JWT token in the `Authorization` header:

```
Authorization: Bearer <jwt-token>
```

The JWT must contain:
- `tenant_id` — identifies the tenant (never accepted from headers or body)
- `sub` — identifies the user
- Standard claims (`iss`, `exp`, `iat`)

For on-prem deployments, configure your OIDC provider (Okta, Azure AD, Keycloak, etc.) as the token issuer.

## Base URL

| Deployment | Base URL |
|-----------|----------|
| On-Prem (default) | `http://localhost:8080` |
| Cloud (GCP) | `https://<your-instance>.run.app` |

All endpoints are prefixed with `/v1/`.

## Core Endpoints

### Context Events

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/nce` | Create a Normalized Context Event |

Ingests relationship signals (emails sent/received, meetings scheduled, calendar events) into the Enterprise Context Ledger.

### Context Retrieval

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/context/query` | Query context capsules |
| `GET` | `/v1/accounts/:id/brief` | Get account brief |
| `POST` | `/v1/search` | Enterprise Ambient Search |

### Relationship Intelligence

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/v1/drift/signals` | Get drift signals |
| `GET` | `/v1/myooo/status` | MyOOO continuity status |

### AI Integration

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/synthesis/run` | BYO-LLM synthesis (Enterprise) |

Allows customers to bring their own LLM and run synthesis against their context data. ContextECF never sends data to external AI services without explicit customer configuration.

### Health Probes

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health/live` | Liveness probe (is the process running?) |
| `GET` | `/health/ready` | Readiness probe (are dependencies healthy?) |

### License (On-Prem)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/v1/license/status` | Current license status, expiry, features |

## Response Headers

All API responses include these headers:

```
X-ContextECF-Mode: READ_ONLY
X-ContextECF-Deterministic: true
X-ContextECF-Execution: false
X-ContextECF-Duration-Ms: <ms>
X-ContextECF-CCU: <count>
```

## Error Responses

All errors follow a consistent format:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required",
    "request_id": "abc123"
  }
}
```

| Status | Meaning |
|--------|---------|
| 400 | Invalid request (validation failed) |
| 401 | Authentication required |
| 402 | License expired (on-prem, write operations only) |
| 403 | Forbidden (ACL denied or tenant isolation violation) |
| 404 | Resource not found |
| 409 | Conflict |
| 500 | Internal server error |

## Rate Limiting

API requests are subject to rate limiting based on your license tier. Rate limit headers are included in responses:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1609459200
```
