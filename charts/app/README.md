# App Chart

**Modern multi-component Helm chart for application deployments (recommended)**

This is the recommended chart for deploying applications with multiple components. It replaces the legacy `stable-app` and `preview-app` charts with a more flexible architecture that supports multiple deployments per release.

## Features

- **Multi-component architecture** - Deploy multiple services (web, worker, scheduler) in a single release
- **Auto-service creation** - Services are automatically created when `containerPort` or `ingress.enabled` is defined
- **Global defaults** - Set common values like `image` and `host` globally, with per-component overrides
- **Security features** - IP whitelisting, security path filters, basic auth support
- **Resource management** - Per-component resource limits, Pod Disruption Budgets
- **Job support** - One-time jobs and scheduled cron jobs
- **Ingress with TLS** - NGINX ingress with automatic TLS via cert-manager and Let's Encrypt

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install my-app enlabs-org/app
```

## Quick Start

### Minimal Configuration

```yaml
components:
  web:
    image: "nginx:latest"
    containerPort: 80
    ingress:
      enabled: true
      host: "my-app.example.com"
```

### Multi-Component Application

```yaml
global:
  image: "myapp:v1.0.0"
  host: "myapp.example.com"
  envFromSecret: app-secrets

components:
  web:
    replicas: 3
    containerPort: 80
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
    ingress:
      enabled: true
      whitelistSourceRange: "10.0.0.0/8"
    pdb:
      enabled: true
      minAvailable: 2
      
  worker:
    replicas: 5
    command: "php artisan queue:work"
    
jobs:
  - name: migrate
    command: "php artisan migrate --force"
    
cronJobs:
  - name: cleanup
    schedule: "0 2 * * *"
    command: "php artisan cleanup"
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.image` | Default container image for all components | `null` |
| `global.host` | Default host for ingress | `null` |
| `global.imagePullPolicy` | Image pull policy | `Always` |
| `global.labels` | Custom labels applied to all resources | `{}` |
| `global.envFromSecret` | Default secret name for environment variables | `null` |
| `global.useDatabaseCert` | Enable database certificate volume | `false` |
| `global.restartAfterRedeploy` | Force pod restart on every deployment | `false` |

### Component Configuration

Each component supports the following configuration:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable this component | `true` |
| `image` | Container image (overrides global.image) | Uses global.image |
| `replicas` | Number of replicas | `1` |
| `containerPort` | Container port (triggers service creation) | `null` |
| `command` | Container command | `null` |
| `resources.requests` | Resource requests | `{}` |
| `resources.limits` | Resource limits | `{}` |
| `livenessProbe.enabled` | Enable liveness probe | `false` |
| `readinessProbe.enabled` | Enable readiness probe | `false` |
| `env` | Environment variables | `[]` |
| `envFromSecret` | Secret name for environment variables | Uses global.envFromSecret |
| `labels` | Component-specific labels | `{}` |

### Service Configuration

Services are auto-created when `containerPort` or `ingress.enabled` is defined:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service (set false to disable auto-creation) | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Hostname (overrides global.host) | Uses global.host |
| `ingress.path` | Path pattern | `/` |
| `ingress.pathType` | Path type | `Prefix` |
| `ingress.tls.enabled` | Enable TLS | `true` |
| `ingress.tls.issuer` | Certificate issuer | `letsencrypt` |
| `ingress.wwwRedirect` | Redirect www subdomain | `false` |
| `ingress.basicAuth.enabled` | Enable basic auth | `false` |
| `ingress.whitelistSourceRange` | IP whitelist (comma-separated) | `""` |
| `ingress.securityPathFilter.enabled` | Block sensitive paths | `false` |
| `ingress.securityPathFilter.blockedPaths` | Array of blocked paths | `["/.git", "/.env"]` |

### Pod Disruption Budget

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pdb.enabled` | Enable PDB | `false` |
| `pdb.minAvailable` | Minimum available pods | `1` |

### Jobs and CronJobs

Jobs are one-time executions:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `jobs[].name` | Job name | Required |
| `jobs[].image` | Container image | Uses global.image |
| `jobs[].command` | Command to execute | Required |
| `jobs[].restartPolicy` | Restart policy | `Never` |
| `jobs[].backoffLimit` | Retry limit | `3` |

CronJobs are scheduled executions:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cronJobs[].name` | CronJob name | Required |
| `cronJobs[].schedule` | Cron schedule | Required |
| `cronJobs[].image` | Container image | Uses global.image |
| `cronJobs[].command` | Command to execute | Required |
| `cronJobs[].concurrencyPolicy` | Concurrency policy | `Allow` |

## Security Features

### IP Whitelisting

Restrict access to specific IP ranges:

```yaml
components:
  web:
    ingress:
      enabled: true
      whitelistSourceRange: "10.0.0.0/8,192.168.0.0/16"
```

**Note:** ACME challenge paths (`/.well-known/acme-challenge/*`) automatically bypass IP whitelist restrictions for certificate renewal.

### Security Path Filter

Block access to sensitive paths:

```yaml
components:
  web:
    ingress:
      enabled: true
      securityPathFilter:
        enabled: true
        blockedPaths:
          - "/.git"
          - "/.env"
          - "/.claude"
          - "/vendor"
```

### Basic Authentication

Protect your application with basic auth:

```yaml
components:
  web:
    ingress:
      enabled: true
      basicAuth:
        enabled: true
        username: "admin"
        password: "secretpassword"
```

## Advanced Features

### Database Certificates

For applications requiring database SSL certificates:

```yaml
global:
  useDatabaseCert: true
  databaseCert:
    secretName: "database-cert"
    mountPath: "/etc/ssl/certs"
```

### Init and Sidecar Containers

```yaml
components:
  web:
    initContainers:
      - name: wait-for-db
        image: "busybox:latest"
        command: "until nc -z db 5432; do sleep 2; done"
    additionalContainers:
      - name: nginx-sidecar
        image: "nginx:alpine"
        port: 8080
```

### FastCGI Support

For PHP applications:

```yaml
components:
  web:
    ingress:
      enabled: true
      fcgi:
        enabled: true
        scriptFilename: "/var/www/html/public/index.php"
```

## Examples

See the test configurations for complete examples:
- [Minimal configuration](../../tests/app/values-minimal.yaml)
- [Full-featured configuration](../../tests/app/values-full.yaml)

## Migration from stable-app/preview-app

The `app` chart replaces the legacy `stable-app` and `preview-app` charts. Key differences:

1. **Multi-component**: Single release can deploy multiple components
2. **Auto-services**: No need to manually configure services
3. **Global defaults**: Set image and host once, inherit everywhere
4. **Simplified structure**: More intuitive configuration hierarchy

### Migration Example

**Legacy stable-app:**
```yaml
image: "myapp:v1.0.0"
host: "myapp.example.com"
useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

**New app chart:**
```yaml
global:
  image: "myapp:v1.0.0"
  host: "myapp.example.com"
  
components:
  web:
    containerPort: 80
    ingress:
      enabled: true
```

## Testing

Generate manifests locally:

```bash
# Minimal configuration
make template-app-minimal

# Full configuration
make template-app

# Output will be in .build/app/
```

## Version History

- **1.0.3** - Current version
- **1.0.0** - Initial release