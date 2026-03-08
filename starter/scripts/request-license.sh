#!/usr/bin/env bash
# ContextECF Fabric — Trial License Request Generator
# Generates a local JSON file with machine identity for license provisioning.
# This script does NOT transmit any data over the network.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_DIR="$(dirname "$SCRIPT_DIR")"
VERSION=$(cat "${STARTER_DIR}/VERSION" 2>/dev/null || echo "unknown")
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
OUTPUT_FILE="${STARTER_DIR}/trial_request_${HOSTNAME}.json"

echo "ContextECF Fabric — Trial License Request"
echo ""

# Collect non-sensitive machine identity
MACHINE_ID="unknown"
if [ -f /etc/machine-id ]; then
  MACHINE_ID=$(cat /etc/machine-id)
elif [ -f /var/lib/dbus/machine-id ]; then
  MACHINE_ID=$(cat /var/lib/dbus/machine-id)
elif command -v ioreg &>/dev/null; then
  # macOS
  MACHINE_ID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}' 2>/dev/null || echo "unknown")
fi

OS_TYPE=$(uname -s 2>/dev/null || echo "unknown")
OS_ARCH=$(uname -m 2>/dev/null || echo "unknown")
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
REQUEST_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT_FILE" <<EOF
{
  "type": "trial_license_request",
  "version": "${VERSION}",
  "requested_at": "${REQUEST_DATE}",
  "machine": {
    "hostname": "${HOSTNAME}",
    "machine_id": "${MACHINE_ID}",
    "os": "${OS_TYPE}",
    "arch": "${OS_ARCH}",
    "docker_version": "${DOCKER_VERSION}"
  }
}
EOF

echo "License request generated: ${OUTPUT_FILE}"
echo ""
echo "Next steps:"
echo "  1. Email this file to: licensing@contextecf.com"
echo "  2. You will receive a license.jwt file"
echo "  3. Place it in: manifests/license.jwt"
echo "  4. Restart the Fabric: ./fabric down && ./fabric up"
echo ""
echo "No data was transmitted. The file is local to this machine."
