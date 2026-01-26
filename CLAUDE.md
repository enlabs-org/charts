# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Helm charts repository for enlabs-org containing Kubernetes deployment configurations. Charts are validated through CI on every PR and automatically released on push to main.

## Development Commands

```bash
# Lint all charts (run this before committing)
make helm-lint

# Generate manifests for all charts (outputs to .build/)
make helm-template

# Generate manifests for a specific chart
make template-app
make template-app-minimal
make template-preview-app
make template-stable-app
make template-metabase
make template-adminer
make template-n8n
make template-rbac

# Clean generated files
make clean
```

## CI Validation Pipeline

The CI pipeline (`helm-dry-run.yml`) runs:
1. `make helm-lint` - Helm validation
2. `make helm-template` - Manifest generation
3. YAML lint on `.build/` output
4. kubeconform with strict mode for Kubernetes schema validation

All checks must pass before merging.

## Charts

| Chart | Purpose |
|-------|---------|
| `app` | Multi-component application deployments (recommended) |
| `stable-app` | Production application deployments (legacy) |
| `preview-app` | Preview/staging application deployments (legacy) |
| `rbac` | Cluster role-based access control |
| `adminer` | Database management UI |
| `metabase` | Business intelligence tool |
| `n8n` | Workflow automation |

## App Chart (Recommended)

The `app` chart is the modern alternative to stable-app/preview-app with multi-component architecture.

**Key features:**
- Multiple deployments per release via `components` map - each can be scaled independently
- Resources limits/requests per component
- PodDisruptionBudget per component
- IP whitelist for VPN restriction (`whitelistSourceRange`)
- Security path filter (blocks .git, .env, etc.)
- Consistent naming and typing

**Structure:**
```yaml
global:
  imagePullPolicy: Always
  envFromSecret: app-secrets
  useDatabaseCert: false

components:
  web:
    image: "myapp-web:v1"
    replicas: 2
    containerPort: 80
    resources:
      requests: {cpu: "100m", memory: "128Mi"}
    service:
      enabled: true
    ingress:
      enabled: true
      host: "app.example.com"
      whitelistSourceRange: "10.0.0.0/8"
      securityPathFilter:
        enabled: true
        blockedPaths: ["/.git", "/.env"]
    pdb:
      enabled: true
      minAvailable: 1
  worker:
    image: "myapp-worker:v1"
    replicas: 5
    command: "php artisan queue:work"

jobs:
  - name: migrate
    image: "myapp-web:v1"
    command: "php artisan migrate"

cronJobs:
  - name: cleanup
    schedule: "0 2 * * *"
    image: "myapp-worker:v1"
    command: "php artisan cleanup"
```

## Legacy Charts (stable-app/preview-app)

**stable-app and preview-app** share nearly identical templates and support:
- Init containers and side containers
- Environment variables from secrets (`envFromSecret`)
- Database certificate volumes (`useDatabaseCert`)
- Jobs and CronJobs
- NGINX ingress with TLS via cert-manager
- Basic auth, FastCGI backend, www redirect

**Key values pattern** - charts use boolean flags to conditionally create resources:
- `useDefaultDeployment`, `useDefaultService`, `useDefaultIngress`
- `tls`, `issueCertificate`, `basicAuth`

## Test Values

Test values are in `tests/<chart-name>/` and are used by the Makefile template commands:
- `tests/app/values-full.yaml` - comprehensive test with all features
- `tests/app/values-minimal.yaml` - minimal working configuration

## Versioning

Chart versions are in each chart's `Chart.yaml`. Bump the version when making changes - releases are automatically created by the release workflow.
