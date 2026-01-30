# Preview App Chart

**Legacy Helm chart for preview/staging application deployments**

⚠️ **Note**: This chart is considered legacy. For new deployments, we recommend using the [`app` chart](../app/README.md) which provides a more flexible multi-component architecture.

This chart is designed for temporary preview/staging deployments and testing environments. It provides similar functionality to `stable-app` but is optimized for development workflows and temporary environments.

## Features

- **Single-component deployment** - One deployment per release
- **Standard Kubernetes resources** - Deployment, Service, Ingress
- **TLS with Let's Encrypt** - Automatic certificate management
- **Basic authentication** - Optional HTTP basic auth protection
- **FastCGI support** - For PHP applications with NGINX
- **Sidecar containers** - Support for additional containers
- **Init containers** - Support for initialization containers
- **Jobs and CronJobs** - One-time and scheduled tasks
- **Database certificates** - SSL certificate volume mounting

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install my-preview-app enlabs-org/preview-app
```

## Quick Start

### Basic Preview Configuration

```yaml
image: "myapp:feature-branch"
host: "feature-branch.preview.example.com"
useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

### Development Configuration

```yaml
image: "myapp:develop"
host: "develop.preview.example.com"
replicas: 1
containerPort: 80

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true

tls: true
issueCertificate: true
basicAuth: true

jobs:
  - name: seed-db
    image: "myapp:develop"
    command: "php artisan db:seed --force"
```

## Configuration

### Deployment Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `useDefaultDeployment` | Create default deployment | `true` |
| `image` | Container image | `""` |
| `replicas` | Number of replicas | `1` |
| `containerPort` | Container port | `80` |
| `livenessProbePath` | Liveness probe HTTP path | `/` |
| `restartAfterRedeploy` | Force restart on deployment | `false` |
| `envFromSecret` | Secret name for environment variables | `null` |
| `env` | Environment variables | `null` |

### Service Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `useDefaultService` | Create default service | `true` |

### Ingress Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `useDefaultIngress` | Create default ingress | `true` |
| `host` | Hostname for ingress | `""` |
| `wwwRedirect` | Redirect www subdomain to apex | `false` |
| `tls` | Enable TLS | `true` |
| `issueCertificate` | Auto-issue certificate via cert-manager | `true` |
| `clusterIssuer` | Certificate issuer | `letsencrypt` |
| `tlsSecretName` | Custom TLS secret name | `""` |
| `basicAuth` | Enable HTTP basic authentication | `false` |
| `fcgi` | Enable FastCGI backend | `false` |
| `fcgi_script_filename` | FastCGI script filename | `""` |

### Container Configuration

#### Sidecar Containers

Additional containers that run alongside the main application:

```yaml
sideContainers:
  - name: redis-proxy
    image: "redis:alpine"
    port: 6379
    env:
      - name: REDIS_URL
        value: "redis://localhost:6379"
```

#### Init Containers

Containers that run before the main application starts:

```yaml
initContainers:
  - name: wait-for-db
    image: "busybox:latest"
    command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]
```

### Database Certificates

For applications requiring database SSL certificates:

```yaml
useDatabaseCert: true
databaseCert: 
  secretName: "database-cert"
  mountPath: "/etc/ssl/certs"
```

### Jobs

One-time job execution for setup tasks:

```yaml
jobs:
  - name: db-migrate
    image: "myapp:feature-branch"
    command: "php artisan migrate --force"
    restartPolicy: "Never"
    backoffLimit: 3
    
  - name: seed-data
    image: "myapp:feature-branch"
    command: "php artisan db:seed --class=TestDataSeeder"
```

### CronJobs

Scheduled job execution:

```yaml
cronJobs:
  - name: cleanup-temp-files
    schedule: "0 */6 * * *"
    image: "myapp:feature-branch"
    command: "php artisan cleanup:temp"
    restartPolicy: "OnFailure"
```

## Use Cases

### Feature Branch Testing

```yaml
image: "myapp:feature-xyz"
host: "feature-xyz.preview.example.com"
replicas: 1

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true

tls: true
issueCertificate: true
basicAuth: true

jobs:
  - name: migrate
    image: "myapp:feature-xyz"
    command: "php artisan migrate --force"
  - name: seed
    image: "myapp:feature-xyz"
    command: "php artisan db:seed --class=DemoSeeder"
```

### PHP Application with FastCGI

```yaml
image: "myapp-php:develop"
host: "develop.preview.example.com"
containerPort: 9000

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true

fcgi: true
fcgi_script_filename: "/var/www/html/public/index.php"

tls: true
issueCertificate: true
basicAuth: true

sideContainers:
  - name: nginx
    image: "nginx:alpine"
    port: 80
```

### Testing with External Services

```yaml
image: "myapp:test"
host: "test.preview.example.com"
envFromSecret: "test-secrets"

initContainers:
  - name: wait-for-services
    image: "busybox:latest"
    command: ["sh", "-c", "until nc -z db 5432 && nc -z redis 6379; do sleep 5; done"]

sideContainers:
  - name: mock-service
    image: "mockserver:latest"
    port: 8080
    env:
      - name: MOCK_CONFIG
        value: "/config/mocks.json"

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

## Testing Workflows

### CI/CD Integration

This chart is commonly used in CI/CD pipelines for:

1. **Pull Request Previews** - Deploy each PR to a unique URL
2. **Feature Branch Testing** - Long-running feature environments  
3. **Integration Testing** - Test with real dependencies
4. **User Acceptance Testing** - Stakeholder review environments

### Example CI/CD Usage

```bash
# Deploy PR preview
helm upgrade --install pr-${PR_NUMBER} enlabs-org/preview-app \
  --set image="myapp:pr-${PR_NUMBER}" \
  --set host="pr-${PR_NUMBER}.preview.example.com" \
  --set basicAuth=true

# Cleanup after PR merge
helm uninstall pr-${PR_NUMBER}
```

## Migration to App Chart

For new deployments, consider migrating to the [`app` chart](../app/README.md) which provides:

- Multi-component architecture
- Better resource organization  
- Auto-service creation
- Enhanced security features
- More intuitive configuration

### Migration Example

**preview-app configuration:**
```yaml
image: "myapp:feature-branch"
host: "feature.preview.example.com"
useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
basicAuth: true
```

**Equivalent app chart configuration:**
```yaml
global:
  image: "myapp:feature-branch"
  host: "feature.preview.example.com"

components:
  web:
    containerPort: 80
    ingress:
      enabled: true
      basicAuth:
        enabled: true
```

## Testing

Generate manifests locally:

```bash
# Uses default values
helm template my-preview-app charts/preview-app/

# Test with custom values  
helm template my-preview-app charts/preview-app/ -f preview-values.yaml
```

## Version History

- **1.13.0** - Current version
- **1.0.0** - Initial release

## Support

This chart is in maintenance mode. For new features and active development, use the [`app` chart](../app/README.md).