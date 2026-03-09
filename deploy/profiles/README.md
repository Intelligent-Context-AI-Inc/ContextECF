# ContextECF Deployment Profiles

This directory contains environment templates for the two supported deployment
modes of ContextECF:

| Profile     | File                  | Description                            |
| ----------- | --------------------- | -------------------------------------- |
| **Cloud**   | `rpaas.env.template`  | Cloud-managed via GCP/AWS Marketplace  |
| **On-Prem** | `onprem.env.template` | Self-hosted in customer infrastructure |

Docker Compose is the **Phase 1 on-prem installer artifact**. Helm charts are
deferred to Phase 2.

---

## Table of Contents

1. [Profile Selection](#profile-selection)
2. [Install (On-Prem)](#install-on-prem)
3. [Mount License File](#mount-license-file)
4. [Upgrade](#upgrade)
5. [Schema Migration Guard](#schema-migration-guard)
6. [Rotate License Key](#rotate-license-key)
7. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
8. [Log Rotation](#log-rotation)
9. [Read-Only Behavior (License Expiry)](#read-only-behavior-license-expiry)
10. [Observability (Phase 2 Note)](#observability-phase-2-note)

---

## Profile Selection

Choose your profile based on the deployment target:

- **Cloud** (`rpaas.env.template`) -- Use when ContextECF is provisioned
  through Google Cloud Marketplace or AWS Marketplace. Infrastructure
  (database, cache, Pub/Sub, secrets) is managed by the cloud platform.
  License enforcement is disabled; billing flows through Stripe and the
  Marketplace SDK.

- **On-Prem** (`onprem.env.template`) -- Use when ContextECF runs inside a
  customer's own data center or private VPC. All infrastructure is co-located.
  A signed JWS license file gates feature access and enforces seat/CCU limits.

To create your environment file, copy the template and fill in the values:

```bash
# Cloud
cp deploy/profiles/rpaas.env.template deploy/profiles/rpaas.env

# On-Prem
cp deploy/profiles/onprem.env.template deploy/profiles/onprem.env
```

> **Security note**: Never commit `.env` files to version control. The
> `.gitignore` at the repository root excludes `*.env` files.

---

## Install (On-Prem)

### Prerequisites

- Docker Engine 24+ and Docker Compose v2+
- PostgreSQL 15 (bundled or external)
- At least 8 GB RAM, 4 CPU cores, 50 GB disk
- A valid ContextECF license file (`license.jwt`) and its public key
  (`license-public.pem`)
- An OIDC-compliant identity provider (Okta, Azure AD, Keycloak, etc.)

### Step 1: Prepare the environment file

```bash
cp deploy/profiles/onprem.env.template deploy/profiles/onprem.env
# Edit deploy/profiles/onprem.env -- fill in ALL required values:
#   - JWT_SECRET (generate with: openssl rand -base64 64)
#   - OIDC_ISSUER_URL (your identity provider)
#   - DATABASE_URL (if using external PostgreSQL)
#   - REDIS_URL (if using external Redis)
```

### Step 2: Place license and auth files

```bash
mkdir -p license
cp /path/to/license.jwt license/license.jwt
cp /path/to/license-public.pem license/license-public.pem

# Generate the internal service auth key
openssl rand -base64 32 > license/internal-auth.key
chmod 600 license/internal-auth.key
```

### Step 3: Run the preflight check

```bash
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env
```

The preflight check validates that all required files, directories, and
services are accessible before starting the application. Fix any FAIL items
before proceeding.

### Step 4: Start services

```bash
docker compose --env-file deploy/profiles/onprem.env up -d
```

### Step 5: Run database migrations

```bash
docker compose exec api-gateway npm run db:migrate
```

### Step 6: Verify the deployment

```bash
# Health check
curl -s http://localhost:8080/health/live | jq .

# Readiness check (confirms database connectivity)
curl -s http://localhost:8080/health/ready | jq .
```

---

## Mount License File

On-prem deployments require the license file and its public key to be mounted
as read-only volumes into all services that enforce licensing (at minimum,
`api-gateway`).

Add the following to your `docker-compose.override.yml` or directly to the
service definition:

```yaml
services:
  api-gateway:
    volumes:
      - ./license/license.jwt:/etc/contextecf/license.jwt:ro
      - ./license/license-public.pem:/etc/contextecf/license-public.pem:ro
      - ./license/internal-auth.key:/etc/contextecf/internal-auth.key:ro
    environment:
      LICENSE_FILE_PATH: /etc/contextecf/license.jwt
      LICENSE_PUBLIC_KEY_PATH: /etc/contextecf/license-public.pem
      INTERNAL_AUTH_PSK_PATH: /etc/contextecf/internal-auth.key
```

If you run multiple services that need license awareness (e.g., `ecl-writer`,
`synthesis`), apply the same volume mounts to each.

The `LICENSE_REFRESH_INTERVAL_S` variable (default: 60 seconds) controls how
often the running process re-reads the license file from disk. This enables
license rotation without restarting containers.

---

## Upgrade

### Overview

Upgrading ContextECF follows a pull-migrate-restart sequence. The schema
migration guard (next section) prevents version mismatches.

### Step 1: Pull new images

```bash
docker compose pull
```

If you build images locally:

```bash
docker compose build --pull
```

### Step 2: Run the preflight check

```bash
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env
```

### Step 3: Stop application services (keep infrastructure)

```bash
# Stop application containers but keep postgres and redis running
docker compose stop api-gateway auth ecl-writer audit directory
```

### Step 4: Run database migrations

```bash
# Start just the migration runner against the running database
docker compose run --rm api-gateway npm run db:migrate
```

### Step 5: Restart application services

```bash
docker compose --env-file deploy/profiles/onprem.env up -d
```

### Step 6: Verify

```bash
curl -s http://localhost:8080/health/ready | jq .
```

> **Rollback**: If the upgrade fails, stop the new containers, restore the
> database from backup (see [Backup and DR](#backup-and-disaster-recovery)),
> and restart with the previous image tags.

---

## Schema Migration Guard

On-prem upgrades **must** verify that the database schema version matches the
container version before starting application services. Running containers
against an incompatible schema can cause data corruption or silent failures.

### How it works

1. The **preflight check script** (`tools/preflight-check.sh`) queries the
   `schema_migrations` table to read the latest applied migration version.
2. It compares that version against the expected migration version embedded in
   the container image.
3. If they do not match, the preflight check exits with a FAIL status and
   prints instructions to run migrations first.

### Manual verification

```bash
# Check the current schema version in the database
docker compose exec postgres psql -U contextecf -d contextecf \
  -c "SELECT name FROM kysely_migration ORDER BY timestamp DESC LIMIT 1;"

# Check the expected version in the container
docker compose run --rm api-gateway node -e \
  "console.log(require('./packages/database/src/migrations/index.js').latestMigration)"
```

### Enforcing the guard

Always run the preflight check before starting services after an image update:

```bash
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env
# If FAIL: run migrations first
docker compose run --rm api-gateway npm run db:migrate
# Then re-run preflight to confirm
bash tools/preflight-check.sh --env-file deploy/profiles/onprem.env
```

---

## Rotate License Key

License keys can be rotated without downtime. The process replaces the license
file on disk and signals the API gateway to reload it.

### Step 1: Replace the license file

```bash
cp /path/to/new-license.jwt license/license.jwt
```

If the public key has also changed:

```bash
cp /path/to/new-license-public.pem license/license-public.pem
```

### Step 2: Signal the API gateway to reload

Send `SIGHUP` to the API gateway process to trigger an immediate license
re-read. Worker services do not need a signal -- they re-read the license file
on their configured interval (`LICENSE_REFRESH_INTERVAL_S`, default 60s).

```bash
docker compose kill -s SIGHUP api-gateway
```

### Step 3: Verify

```bash
# Confirm the license was loaded (check logs for "license reloaded" message)
docker compose logs --tail=20 api-gateway | grep -i license

# Verify write endpoints are accessible (returns 200, not 402)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health/ready
```

> **No downtime**: The `SIGHUP` signal triggers an in-process reload. The API
> gateway continues serving requests throughout the rotation. Worker services
> pick up the new license on their next refresh interval.

---

## Backup and Disaster Recovery

### PostgreSQL Backup

Schedule regular `pg_dump` backups of the ContextECF database. The recommended
schedule is:

| Backup Type   | Frequency  | Retention |
| ------------- | ---------- | --------- |
| Full dump     | Daily      | 30 days   |
| WAL archiving | Continuous | 7 days    |

```bash
# Full backup (run from cron or a scheduled job)
docker compose exec postgres pg_dump -U contextecf -Fc contextecf \
  > /backup/contextecf-$(date +%Y%m%d-%H%M%S).dump

# Restore from backup
docker compose exec -T postgres pg_restore -U contextecf -d contextecf \
  < /backup/contextecf-20260101-120000.dump
```

For production deployments, configure PostgreSQL WAL archiving for
point-in-time recovery. See the PostgreSQL documentation for
`archive_command` and `restore_command` settings.

### Redis Snapshot

Redis is used as a cache (L2) and for rate limiting state. Data loss is
tolerable but inconvenient. Enable periodic RDB snapshots:

```bash
# Trigger a manual snapshot
docker compose exec redis redis-cli BGSAVE

# The RDB file is stored in the redis_data volume
# Copy it to your backup location
docker compose exec redis cat /data/dump.rdb > /backup/redis-$(date +%Y%m%d).rdb
```

For the bundled Redis container, RDB persistence is enabled by default (Alpine
image defaults). To configure snapshot frequency, mount a custom `redis.conf`:

```yaml
services:
  redis:
    volumes:
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf:ro
    command: ['redis-server', '/usr/local/etc/redis/redis.conf']
```

### License File Backup

The license file is a critical operational asset. Maintain a backup copy in a
secure location separate from the application deployment:

```bash
# Include license files in your backup routine
cp license/license.jwt /backup/license/license.jwt
cp license/license-public.pem /backup/license/license-public.pem
cp license/internal-auth.key /backup/license/internal-auth.key
```

> **Recovery order**: When restoring from a disaster, restore in this order:
>
> 1. PostgreSQL database
> 2. License files
> 3. Redis (optional -- cache rebuilds automatically)
> 4. Start application services
> 5. Run preflight check to verify

---

## Log Rotation

### Docker Log Driver Limits

The `LocalStorageProvider` (used when `STORAGE_PROVIDER=local`) writes audit
archives and capsule exports to disk. Combined with application logs, this can
fill disk on long-running deployments.

Configure Docker log driver limits to prevent unbounded log growth. Add these
options to your Docker daemon configuration (`/etc/docker/daemon.json`) or
per-service in `docker-compose.override.yml`:

**Global (daemon.json)**:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
```

**Per-service (docker-compose.override.yml)**:

```yaml
services:
  api-gateway:
    logging:
      driver: json-file
      options:
        max-size: '100m'
        max-file: '5'
  ecl-writer:
    logging:
      driver: json-file
      options:
        max-size: '100m'
        max-file: '5'
```

### Audit Archive Rotation

The audit service writes immutable audit logs that must be retained for
compliance. Configure an archive rotation policy:

| Data Type            | Retention           | Action After Retention      |
| -------------------- | ------------------- | --------------------------- |
| Audit logs (hot)     | 90 days             | Archive to external storage |
| Audit logs (archive) | Per customer policy | Customer-managed            |
| Application logs     | 30 days             | Delete                      |
| Capsule exports      | 60 days             | Archive to external storage |

For on-prem deployments, implement a cron job to rotate audit archives from
`$STORAGE_BASE_PATH`:

```bash
# Example: archive audit logs older than 90 days to an external location
find /var/lib/contextecf/storage/audit \
  -name "*.jsonl" -mtime +90 \
  -exec mv {} /archive/contextecf/audit/ \;

# Example: delete application logs older than 30 days
find /var/lib/contextecf/storage/logs \
  -name "*.log" -mtime +30 -delete
```

### Disk Usage Monitoring

Monitor disk usage on the storage volume to prevent out-of-space conditions:

```bash
# Check storage usage
du -sh /var/lib/contextecf/storage/
du -sh /var/lib/contextecf/storage/*/

# Set up a cron alert (example: warn at 80% usage)
USAGE=$(df /var/lib/contextecf/storage | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$USAGE" -gt 80 ]; then
  echo "WARNING: ContextECF storage at ${USAGE}% capacity"
fi
```

---

## Read-Only Behavior (License Expiry)

When an on-prem license expires, ContextECF enters a degraded read-only mode.
Write operations that create new data are blocked with HTTP 402 responses.
Read access to existing data is **never** blocked -- customers always retain
full access to their Enterprise Context Ledger data.

### What is blocked vs. what remains accessible

| Service          | Blocked When Expired (HTTP 402)                                              | Always Allowed                                                              |
| ---------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **api-gateway**  | Routes to synthesis, `ecl-writer` POST                                       | All GET/read routes, health probes, audit export                            |
| **synthesis**    | All generation routes (`/run`, `/crc/synthesize`)                            | Status, invocations, config reads                                           |
| **ecl-writer**   | `POST /v1/nce` (new event ingestion)                                         | Health probes                                                               |
| **provisioning** | `POST /v1/tenants` (create tenant), `POST /v1/tenants/*/users` (invite user) | `GET /v1/tenants` (list existing), `GET /v1/tenants/*/status` (read status) |

### Non-negotiable guarantee

> Read, export, and audit access to customer-owned ECL data is **NEVER**
> blocked, even after license expiry. This is a core ContextECF principle:
> customers own their data.

### What to expect

1. **Immediate**: Write endpoints return HTTP 402 with a structured error body
   containing the expiry timestamp and renewal instructions.
2. **Ongoing**: Read endpoints, health probes, and audit export continue
   operating normally with no degradation.
3. **After renewal**: Replace the license file and send `SIGHUP` to the API
   gateway (see [Rotate License Key](#rotate-license-key)). Write access
   restores immediately.

### Testing license expiry behavior

To verify your monitoring and alerting catches license expiry:

```bash
# Check current license status
curl -s http://localhost:8080/v1/license/status | jq .

# The response includes:
# - valid: boolean
# - expires_at: ISO 8601 timestamp
# - features: list of licensed features
# - seats: current/max seat counts
```

---

## Observability (Phase 2 Note)

> **Phase 2 enhancement**: Enterprise trials will demand resource visibility.
> Phase 2 adds Prometheus metrics endpoints and pre-configured Grafana
> dashboards for ContextECF services. This section documents what is available
> in Phase 1.

### Phase 1: Docker Stats and Log-Based Monitoring

In the Phase 1 deployment, use Docker's built-in tooling for resource
monitoring:

#### Container resource usage

```bash
# Real-time resource usage for all ContextECF containers
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# One-shot snapshot (useful for cron-based monitoring)
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

#### Health endpoint monitoring

```bash
# Liveness probe (is the process running?)
curl -sf http://localhost:8080/health/live || echo "API gateway is DOWN"

# Readiness probe (is the service ready to accept traffic?)
curl -sf http://localhost:8080/health/ready || echo "API gateway is NOT READY"
```

Set up a cron job or external monitor to poll these endpoints at regular
intervals (recommended: every 30 seconds).

#### Log-based monitoring

Application logs are written to stdout in structured JSON format. Use Docker
log commands or a log aggregator to search for errors and warnings:

```bash
# Follow logs for a specific service
docker compose logs -f api-gateway

# Search for errors across all services
docker compose logs --since 1h | grep '"level":"error"'

# Search for license-related events
docker compose logs api-gateway | grep -i license
```

#### Recommended monitoring checklist (Phase 1)

| Check                    | Command                                                 | Frequency |
| ------------------------ | ------------------------------------------------------- | --------- |
| API gateway health       | `curl -sf localhost:8080/health/ready`                  | Every 30s |
| Container resource usage | `docker stats --no-stream`                              | Every 5m  |
| Disk usage               | `df -h /var/lib/contextecf/storage`                     | Every 15m |
| PostgreSQL connectivity  | `docker compose exec postgres pg_isready`               | Every 1m  |
| Redis connectivity       | `docker compose exec redis redis-cli ping`              | Every 1m  |
| License validity         | `curl -sf localhost:8080/v1/license/status`             | Every 1h  |
| Error rate in logs       | `docker compose logs --since 5m \| grep error \| wc -l` | Every 5m  |

### Phase 2 Preview

Phase 2 will introduce:

- **Prometheus metrics endpoint** (`/metrics`) on each service exposing
  request latency, error rates, queue depths, and cache hit ratios
- **Grafana dashboards** pre-configured for ContextECF service topology
- **Alertmanager rules** for SLA-critical thresholds (P99 latency, error
  budget, license expiry warning)
- **OpenTelemetry traces** for end-to-end request tracing across services

These will be distributed as additional Docker Compose overlay files in
`deploy/monitoring/`.
