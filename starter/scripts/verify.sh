#!/usr/bin/env bash
# ContextECF Fabric — Service Health Verification
# Polls /health/live endpoints until all services are ready or timeout expires.
# Output is status-code only — response bodies are never logged.
set -euo pipefail

TIMEOUT="${FABRIC_VERIFY_TIMEOUT:-120}"
INTERVAL=5
ELAPSED=0

# Services and their externally reachable health endpoints.
# Internal-only services are checked via docker compose exec.
ENDPOINTS=(
  "http://localhost:8080/health/live|API Gateway"
  "http://localhost:3000/health|Admin Console"
)

echo "Verifying ContextECF Fabric services (timeout: ${TIMEOUT}s)..."
echo ""

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  HEALTHY=true
  for entry in "${ENDPOINTS[@]}"; do
    URL="${entry%%|*}"
    NAME="${entry##*|}"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
      echo "  [OK]   ${NAME} (${STATUS})"
    else
      echo "  [WAIT] ${NAME} (${STATUS})"
      HEALTHY=false
    fi
  done

  if [ "$HEALTHY" = true ]; then
    echo ""
    echo "All services healthy."
    exit 0
  fi

  echo "  Waiting ${INTERVAL}s... (${ELAPSED}/${TIMEOUT}s)"
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
  echo ""
done

echo "ERROR: Services did not become healthy within ${TIMEOUT}s."
echo "Run './fabric logs' to investigate."
exit 1
