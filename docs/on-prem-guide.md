# ContextECF On-Prem Deployment Guide

Deploy ContextECF inside your own infrastructure with full data sovereignty. All data stays within your network boundary.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Install (Fabric Starter)](#quick-install-fabric-starter)
3. [Production Install (Docker Compose)](#production-install-docker-compose)
4. [Configuration Reference](#configuration-reference)
5. [License Management](#license-management)
6. [Upgrade Procedure](#upgrade-procedure)
7. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
8. [Log Rotation](#log-rotation)
9. [Monitoring (Phase 1)](#monitoring-phase-1)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Minimum | Recommended (Production) |
|-------------|---------|--------------------------|
| CPU | 2 cores | 4+ cores |
| RAM | 8 GB | 16+ GB |
| Disk | 10 GB free | 50+ GB SSD |
| Docker Engine | 20.10+ | 24+ |
| Docker Compose | v2+ | v2+ |
| PostgreSQL | 15 (bundled) | 15+ (external, managed) |
| Redis | 7 (bundled) | 7+ (external, managed) |
| OIDC Provider | — | Okta, Azure AD, Keycloak |

---

## Quick Install (Fabric Starter)

The Fabric Starter is a one-command installer for evaluation and trial deployments.

```bash
# 1. Get your trial credentials at https://contextecf.com/trial
export REGISTRY_TOKEN=<your-token>
export REGISTRY=<your-registry-url>

# 2. Navigate to the starter directory
cd starter/

# 3. Run the installer
./install.sh
```

The installer will:
- Verify system requirements (`./fabric doctor`)
- Authenticate with the container registry
- Generate a secure environment file
- Pull and start all services
- Run health verification

### Fabric CLI Commands

```bash
./fabric up              # Start all services
./fabric down            # Stop all services
./fabric status          # Show service status
./fabric logs            # View all logs
./fabric logs api-gateway # View specific service logs
./fabric verify          # Run health checks
./fabric doctor          # Check prerequisites
./fabric request-license # Generate trial license request
```

---

## Production Install (Docker Compose)

For production deployments, use the full configuration profile.

### Step 1: Prepare the environment file

```bash
cp deploy/profiles/onprem.env.template deploy/profiles/onprem.env
```

Edit `deploy/profiles/onprem.env` and fill in all required values:

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET` | Yes | `openssl rand -base64 64` |
| `OIDC_ISSUER_URL` | Yes | Your identity provider URL |
| `DATABASE_URL` | Yes (if external) | PostgreSQL connection string |
| `REDIS_URL` | Yes (if external) | Redis connection string |

### Step 2: Place license and auth files

```bash
mkdir -p license
cp /path/to/license.jwt license/license.jwt
cp /path/to/license-public.pem license/license-public.pem

# Generate internal service auth key
openssl rand -base64 32 > license/internal-auth.key
chmod 600 license/internal-auth.key
```

### Step 3: Run the preflight check

```bash
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env
```

Fix any FAIL items before proceeding.

### Step 4: Start services

```bash
docker compose --env-file deploy/profiles/onprem.env up -d
```

### Step 5: Run database migrations

```bash
docker compose exec api-gateway npm run db:migrate
```

### Step 6: Verify

```bash
curl -s http://localhost:8080/health/live | jq .
curl -s http://localhost:8080/health/ready | jq .
```

---

## Configuration Reference

### Deployment Mode

```bash
DEPLOYMENT_MODE=onprem
ENTITLEMENT_PROVIDER=license
SECRET_PROVIDER=local
EVENTS_PROVIDER=local
STORAGE_PROVIDER=local
STORAGE_BASE_PATH=/var/lib/contextecf/storage
```

### License

```bash
LICENSE_ENABLED=true
LICENSE_FILE_PATH=/etc/contextecf/license.jwt
LICENSE_PUBLIC_KEY_PATH=/etc/contextecf/license-public.pem
LICENSE_REFRESH_INTERVAL_S=60
```

### Internal Authentication

```bash
INTERNAL_AUTH_MODE=psk
INTERNAL_AUTH_PSK_PATH=/etc/contextecf/internal-auth.key
```

### External Authentication

```bash
OIDC_ISSUER_URL=https://login.example.com/realms/contextecf
JWT_SECRET=<generated>
JWT_ISSUER=https://auth.contextecf.local
```

### Services

```bash
PORT=8080
NODE_ENV=production
LOG_LEVEL=info
```

---

## License Management

### Trial License

1. Run `./fabric request-license` (or `bash scripts/request-license.sh`)
2. Send the generated `trial_request_*.json` to licensing@contextecf.com
3. Place received `license.jwt` in `manifests/` (starter) or `license/` (production)
4. Restart services

### License Rotation (Zero Downtime)

```bash
# 1. Replace the license file
cp /path/to/new-license.jwt license/license.jwt

# 2. Signal API gateway to reload immediately
docker compose kill -s SIGHUP api-gateway

# 3. Worker services reload automatically (every 60s by default)
```

### License Expiry Behavior

| Operation | Behavior When Expired |
|-----------|----------------------|
| Read / query / search | **Always allowed** |
| Export / audit access | **Always allowed** |
| Write (new events, new tenants) | **HTTP 402** (Payment Required) |
| Health probes | **Always allowed** |

**Guarantee**: Read and export access to your data is **never** blocked, even after license expiry. You always own your data.

---

## Upgrade Procedure

```bash
# 1. Pull new images
docker compose pull

# 2. Run preflight check
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env

# 3. Stop app services (keep database and cache running)
docker compose stop api-gateway auth ecl-writer audit directory

# 4. Run database migrations
docker compose run --rm api-gateway npm run db:migrate

# 5. Restart services
docker compose --env-file deploy/profiles/onprem.env up -d

# 6. Verify
curl -s http://localhost:8080/health/ready | jq .
```

**Rollback**: If the upgrade fails, stop the new containers, restore the database from backup, and restart with the previous image tags.

---

## Backup and Disaster Recovery

### PostgreSQL

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full dump | Daily | 30 days |
| WAL archiving | Continuous | 7 days |

```bash
# Full backup
docker compose exec postgres pg_dump -U contextecf -Fc contextecf \
  > /backup/contextecf-$(date +%Y%m%d-%H%M%S).dump

# Restore
docker compose exec -T postgres pg_restore -U contextecf -d contextecf \
  < /backup/contextecf-20260101-120000.dump
```

### Redis

Redis is used as a cache. Data loss is tolerable — caches rebuild automatically.

### License Files

Maintain backup copies of `license.jwt`, `license-public.pem`, and `internal-auth.key` in a secure location.

### Recovery Order

1. Restore PostgreSQL database
2. Restore license files
3. Restore Redis (optional)
4. Start application services
5. Run preflight check

---

## Log Rotation

Configure Docker log limits to prevent unbounded growth:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
```

### Audit Archive Retention

| Data Type | Retention | Action |
|-----------|-----------|--------|
| Audit logs (hot) | 90 days | Archive to external storage |
| Application logs | 30 days | Delete |
| Capsule exports | 60 days | Archive |

---

## Monitoring (Phase 1)

### Health Endpoint Monitoring

```bash
# Liveness (is it running?)
curl -sf http://localhost:8080/health/live || echo "DOWN"

# Readiness (is it healthy?)
curl -sf http://localhost:8080/health/ready || echo "NOT READY"
```

### Resource Monitoring

```bash
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

### Recommended Checks

| Check | Command | Frequency |
|-------|---------|-----------|
| API health | `curl -sf localhost:8080/health/ready` | Every 30s |
| Container resources | `docker stats --no-stream` | Every 5m |
| Disk usage | `df -h /var/lib/contextecf/storage` | Every 15m |
| PostgreSQL | `docker compose exec postgres pg_isready` | Every 1m |
| Redis | `docker compose exec redis redis-cli ping` | Every 1m |
| License validity | `curl -sf localhost:8080/v1/license/status` | Every 1h |

### Phase 2 (Coming)

- Prometheus metrics endpoints (`/metrics`)
- Pre-configured Grafana dashboards
- Alertmanager rules
- OpenTelemetry distributed tracing

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| All requests return 401 | JWT token invalid or OIDC misconfigured | Verify `OIDC_ISSUER_URL` and token issuer |
| Write endpoints return 402 | License expired | Rotate license (see above) |
| All requests return 403 | Tenant ID mismatch or ACL error | Check JWT `tenant_id` claim |
| `/health/ready` returns 503 | Database or Redis unreachable | Check `DATABASE_URL` and `REDIS_URL` connectivity |
| "Module not found" in logs | Image version mismatch | Run preflight check, apply migrations |
| Services won't start | Schema version mismatch | Run `docker compose run --rm api-gateway npm run db:migrate` |
