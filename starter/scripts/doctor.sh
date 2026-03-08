#!/usr/bin/env bash
# ContextECF Fabric — System Prerequisites Check
# Verifies that the host environment meets minimum requirements.
set -euo pipefail

PASS=0
WARN=0
FAIL=0

check_pass() { echo "  [OK]   $1"; PASS=$((PASS + 1)); }
check_warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }
check_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "ContextECF Fabric — System Check"
echo ""

# 1. Docker Engine
if command -v docker &>/dev/null; then
  DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
  if [ "$DOCKER_VERSION" = "unknown" ]; then
    check_fail "Docker Engine is installed but not responding (is the daemon running?)"
  else
    check_pass "Docker Engine ${DOCKER_VERSION}"
  fi
else
  check_fail "Docker Engine is not installed (https://docs.docker.com/get-docker/)"
fi

# 2. Docker Compose v2
if docker compose version &>/dev/null; then
  COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
  check_pass "Docker Compose ${COMPOSE_VERSION}"
else
  check_fail "Docker Compose v2 is not installed (https://docs.docker.com/compose/install/)"
fi

# 3. Available RAM (minimum 8 GB)
if command -v free &>/dev/null; then
  TOTAL_RAM_KB=$(free | awk '/^Mem:/ {print $2}')
  TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
  if [ "$TOTAL_RAM_GB" -ge 8 ]; then
    check_pass "RAM: ${TOTAL_RAM_GB} GB available (minimum 8 GB)"
  elif [ "$TOTAL_RAM_GB" -ge 4 ]; then
    check_warn "RAM: ${TOTAL_RAM_GB} GB available (8 GB recommended, may experience instability)"
  else
    check_fail "RAM: ${TOTAL_RAM_GB} GB available (minimum 8 GB required)"
  fi
elif command -v sysctl &>/dev/null; then
  # macOS
  TOTAL_RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
  TOTAL_RAM_GB=$((TOTAL_RAM_BYTES / 1024 / 1024 / 1024))
  if [ "$TOTAL_RAM_GB" -ge 8 ]; then
    check_pass "RAM: ${TOTAL_RAM_GB} GB available (minimum 8 GB)"
  elif [ "$TOTAL_RAM_GB" -ge 4 ]; then
    check_warn "RAM: ${TOTAL_RAM_GB} GB available (8 GB recommended)"
  else
    check_fail "RAM: ${TOTAL_RAM_GB} GB available (minimum 8 GB required)"
  fi
else
  check_warn "Could not determine available RAM"
fi

# 4. Available disk space (minimum 10 GB)
if command -v df &>/dev/null; then
  AVAIL_KB=$(df -k . | awk 'NR==2 {print $4}')
  AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
  if [ "$AVAIL_GB" -ge 10 ]; then
    check_pass "Disk: ${AVAIL_GB} GB free (minimum 10 GB)"
  elif [ "$AVAIL_GB" -ge 5 ]; then
    check_warn "Disk: ${AVAIL_GB} GB free (10 GB recommended)"
  else
    check_fail "Disk: ${AVAIL_GB} GB free (minimum 10 GB required)"
  fi
fi

# 5. Port availability
REQUIRED_PORTS=(8080 3000 5432)
PORT_NAMES=("API Gateway" "Admin Console" "PostgreSQL")

for i in "${!REQUIRED_PORTS[@]}"; do
  PORT="${REQUIRED_PORTS[$i]}"
  NAME="${PORT_NAMES[$i]}"
  if command -v ss &>/dev/null; then
    if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
      check_fail "Port ${PORT} (${NAME}) is already in use"
    else
      check_pass "Port ${PORT} (${NAME}) is available"
    fi
  elif command -v lsof &>/dev/null; then
    if lsof -iTCP:"${PORT}" -sTCP:LISTEN &>/dev/null; then
      check_fail "Port ${PORT} (${NAME}) is already in use"
    else
      check_pass "Port ${PORT} (${NAME}) is available"
    fi
  else
    check_warn "Port ${PORT} (${NAME}) — could not verify availability"
  fi
done

# 6. Proxy detection
if [ -n "${HTTP_PROXY:-}" ] || [ -n "${HTTPS_PROXY:-}" ]; then
  check_warn "HTTP proxy detected — ensure Docker is configured to use it"
fi

# Summary
echo ""
echo "Results: ${PASS} passed, ${WARN} warnings, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Please resolve the failures above before proceeding."
  exit 1
fi

if [ "$WARN" -gt 0 ]; then
  echo "Warnings detected — the Fabric may still run but could experience issues."
fi
