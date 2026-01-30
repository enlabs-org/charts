# Stable App Chart

**Legacy Helm chart for production application deployments**

⚠️ **Note**: This chart is considered legacy. For new deployments, we recommend using the [`app` chart](../app/README.md) which provides a more flexible multi-component architecture.

This chart provides a simplified deployment pattern for single-component production applications with standard Kubernetes resources (Deployment, Service, Ingress) and support for jobs, cron jobs, and various deployment patterns.

## Features

- **Single-component deployment** - One deployment per release
- **Standard Kubernetes resources** - Deployment, Service, Ingress
- **TLS with Let's Encrypt** - Automatic certificate management
- **Basic authentication** - Optional HTTP basic auth protection
- **FastCGI support** - For PHP applications with NGINX
- **Init containers** - Support for initialization containers
- **Jobs and CronJobs** - One-time and scheduled tasks
- **Database certificates** - SSL certificate volume mounting

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install my-app enlabs-org/stable-app
```

## Quick Start

### Basic Configuration

```yaml
image: "nginx:latest"
host: "my-app.example.com"
useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

### Production Configuration

```yaml
image: "myapp:v1.2.3"
host: "myapp.example.com"
replicas: 3
containerPort: 80

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true

tls: true
issueCertificate: true
clusterIssuer: "letsencrypt"

jobs:
  - name: migrate
    image: "myapp:v1.2.3"
    command: "php artisan migrate --force"

cronJobs:
  - name: cleanup
    schedule: "0 2 * * *"
    image: "myapp:v1.2.3"
    command: "php artisan cleanup"
```

## Configuration

### Deployment Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `useDefaultDeployment` | Create default deployment | `true` |
| `image` | Container image | `""` |
| `command` | Container command override | `null` |
| `replicas` | Number of replicas | `1` |
| `containerPort` | Container port | `80` |
| `livenessProbePath` | Liveness probe HTTP path | `/` |
| `restartAfterRedeploy` | Force restart on deployment | `false` |
| `envFromSecret` | Secret name for environment variables | `null` |

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

### Init Containers

Support for initialization containers:

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

One-time job execution:

```yaml
jobs:
  - name: db-migrate
    image: "myapp:v1.0.0"
    command: "php artisan migrate --force"
    restartPolicy: "Never"
    backoffLimit: 3
```

### CronJobs

Scheduled job execution:

```yaml
cronJobs:
  - name: cleanup
    schedule: "0 2 * * *"
    image: "myapp:v1.0.0" 
    command: "php artisan cleanup"
    restartPolicy: "OnFailure"
    concurrencyPolicy: "Forbid"
```

## Examples

### Simple Web Application

```yaml
image: "nginx:latest"
host: "www.example.com"
replicas: 2
containerPort: 80

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true

tls: true
issueCertificate: true
wwwRedirect: true
```

### PHP Application with FastCGI

```yaml
image: "myapp-php:latest"
host: "php-app.example.com"
replicas: 3

useDefaultDeployment: true
useDefaultService: true  
useDefaultIngress: true

tls: true
issueCertificate: true
basicAuth: true

jobs:
  - name: migrate
    image: "myapp-php:latest"
    command: "php artisan migrate --force"

cronJobs:
  - name: cache-clear
    schedule: "0 3 * * *"
    image: "myapp-php:latest"
    command: "php artisan cache:clear"
```

### Application with Database Certificates

```yaml
image: "myapp:latest"
host: "secure-app.example.com"
envFromSecret: "app-secrets"
useDatabaseCert: true
databaseCert:
  secretName: "db-ssl-cert"
  mountPath: "/etc/ssl/certs"

useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

## Migration to App Chart

For new deployments, consider migrating to the [`app` chart](../app/README.md) which provides:

- Multi-component architecture
- Better resource organization
- Auto-service creation
- Enhanced security features
- More intuitive configuration

### Migration Example

**stable-app configuration:**
```yaml
image: "myapp:v1.0.0"
host: "myapp.example.com"
replicas: 3
useDefaultDeployment: true
useDefaultService: true
useDefaultIngress: true
```

**Equivalent app chart configuration:**
```yaml
global:
  image: "myapp:v1.0.0"
  host: "myapp.example.com"
  
components:
  web:
    replicas: 3
    containerPort: 80
    ingress:
      enabled: true
```

## Testing

Generate manifests locally:

```bash
# Uses default values
helm template my-app charts/stable-app/

# Test with custom values
helm template my-app charts/stable-app/ -f my-values.yaml
```

## Version History

- **1.8.0** - Current version
- **1.0.0** - Initial release

## Support

This chart is in maintenance mode. For new features and active development, use the [`app` chart](../app/README.md).