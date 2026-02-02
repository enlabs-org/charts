# Helm Charts

![Helm Charts](https://github.com/enlabs-org/charts/actions/workflows/helm-dry-run.yml/badge.svg?branch=main)

A collection of production-ready Helm charts for enlabs-org, validated through CI and automatically released. Each chart includes comprehensive documentation, security features, and follows Kubernetes best practices.

## Installation

Add the repository:

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm repo update
```

## Available Charts

| Chart | Description | Documentation |
|-------|-------------|---------------|
| **[app](charts/app/)** | Multi-component application deployments (recommended) | [📖 README](charts/app/README.md) |
| **[stable-app](charts/stable-app/)** | Legacy production application deployments | [📖 README](charts/stable-app/README.md) |
| **[preview-app](charts/preview-app/)** | Legacy preview/staging application deployments | [📖 README](charts/preview-app/README.md) |
| **[rbac](charts/rbac/)** | Role-based access control management | [📖 README](charts/rbac/README.md) |
| **[adminer](charts/adminer/)** | Database management UI | [📖 README](charts/adminer/README.md) |
| **[metabase](charts/metabase/)** | Business intelligence platform | [📖 README](charts/metabase/README.md) |
| **[n8n](charts/n8n/)** | Workflow automation tool | [📖 README](charts/n8n/README.md) |
| **[k8s-pwa-dashboard](charts/k8s-pwa-dashboard/)** | Kubernetes deployment dashboard | [📖 README](charts/k8s-pwa-dashboard/README.md) |

## Chart Categories

### Application Deployment
- **app** - Modern multi-component architecture (recommended)
- **stable-app** - Legacy single-component production deployments  
- **preview-app** - Legacy preview/staging environments

### Database & Analytics
- **adminer** - Universal database management interface
- **metabase** - Business intelligence and data visualization

### Security & Automation
- **rbac** - Cluster access control and user permissions
- **n8n** - Workflow automation and integration platform

### Monitoring & Operations
- **k8s-pwa-dashboard** - Simple dashboard for monitoring and scaling deployments

## Migration Guide

If you're currently using `stable-app` or `preview-app`, we recommend migrating to the modern **app** chart:

- ✅ Multi-component deployments in a single release
- ✅ Auto-service creation and improved resource management  
- ✅ Enhanced security features and ingress controls
- ✅ Global defaults with per-component overrides

See the [app chart migration guide](charts/app/README.md#migration-from-legacy-charts) for detailed instructions.

## Quick Examples

### Simple Web Application
```bash
helm install my-app enlabs-org/app --set components.web.image=nginx:latest \
  --set components.web.containerPort=80 \
  --set components.web.ingress.enabled=true \
  --set components.web.ingress.host=my-app.example.com
```

### Database Management UI
```bash
helm install adminer enlabs-org/adminer \
  --set ingress.enabled=true \
  --set ingress.host=adminer.example.com
```

---

## Development

```bash
# Lint all charts
make helm-lint

# Generate manifests
make helm-template

# Clean generated files
make clean
```
