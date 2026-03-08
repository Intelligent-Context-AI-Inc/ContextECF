# ContextECF Helm Chart Guide

Deploy ContextECF to Kubernetes using the official Helm chart.

> **Status**: The Helm chart is a Phase 2 deployment artifact. Docker Compose is the Phase 1 installer. The Helm chart is included for organizations planning Kubernetes-based deployments.

---

## Prerequisites

- Kubernetes 1.25+
- Helm 3.10+
- PostgreSQL 15+ (external, not bundled)
- Redis 7+ (external, not bundled)
- OIDC provider configured
- ContextECF license file

## Installation

```bash
# From the repository root
helm install contextecf deploy/helm/contextecf \
  --namespace contextecf \
  --create-namespace \
  --values my-values.yaml
```

## Configuration

Create a `my-values.yaml` with your environment-specific settings:

```yaml
global:
  deploymentMode: on_prem
  placementMode: customer_network

database:
  url: "postgres://contextecf:password@your-postgres:5432/contextecf"

redis:
  url: "redis://your-redis:6379"

auth:
  oidcIssuerUrl: "https://login.example.com/realms/contextecf"
  jwtSecret:
    secretRef: "contextecf-jwt-secret"

license:
  enabled: true
  fileSecretRef: "contextecf-license"

internalAuth:
  mode: psk
  pskSecretRef: "contextecf-internal-auth"
```

## Chart Structure

```
deploy/helm/contextecf/
  Chart.yaml          # Chart metadata
  values.yaml         # Default configuration
  templates/
    deployment.yaml   # Multi-service deployment
    configmap.yaml    # Configuration
    secrets.yaml      # Secret references
    service.yaml      # Kubernetes services
    networkpolicy.yaml # Network isolation
    hpa.yaml          # Horizontal Pod Autoscaling
    namespace.yaml    # Namespace creation
```

## Secrets Management

The Helm chart uses `secretRef:` and `kmsref:` patterns — secrets are never embedded in values files. Create Kubernetes secrets before installing:

```bash
# JWT secret
kubectl create secret generic contextecf-jwt-secret \
  --namespace contextecf \
  --from-literal=jwt-secret="$(openssl rand -base64 64)"

# License file
kubectl create secret generic contextecf-license \
  --namespace contextecf \
  --from-file=license.jwt=/path/to/license.jwt \
  --from-file=license-public.pem=/path/to/license-public.pem

# Internal auth key
kubectl create secret generic contextecf-internal-auth \
  --namespace contextecf \
  --from-file=internal-auth.key=/path/to/internal-auth.key
```

## Scaling

Horizontal Pod Autoscaling is disabled by default. Enable it in your values:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilization: 70
```

## Network Policies

Network policies are included to restrict inter-service traffic. Services can only communicate with their declared dependencies.
