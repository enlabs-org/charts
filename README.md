# Helm Charts

![Helm Charts](https://github.com/enlabs-org/charts/actions/workflows/helm-dry-run.yml/badge.svg?branch=main)

## Available Charts

| Chart | Description |
|-------|-------------|
| [app](#app) | Multi-component application deployments |
| [adminer](#adminer) | Database management UI |
| [metabase](#metabase) | Business intelligence tool |
| [n8n](#n8n) | Workflow automation |
| [rbac](#rbac) | Cluster role-based access control |

---

## App

Multi-component application chart supporting multiple deployments, services, and ingresses in a single release.

### Features

- Multiple independent components (web, worker, api, etc.)
- Per-component scaling and resources
- PodDisruptionBudget support
- Init containers and sidecars
- Jobs and CronJobs
- TLS with cert-manager
- IP whitelisting
- Security path filtering
- Basic authentication
- FastCGI support

### Basic Example

```yaml
global:
  imagePullPolicy: Always
  envFromSecret: my-app-secrets

components:
  web:
    image: "myapp:latest"
    replicas: 2
    containerPort: 80
    service:
      enabled: true
    ingress:
      enabled: true
      host: "app.example.com"
```

### Full Example

```yaml
global:
  imagePullPolicy: Always
  envFromSecret: my-app-secrets
  useDatabaseCert: true
  databaseCert:
    mountPath: "/etc/ssl/certs"
    secretName: "database-cert"
  restartAfterRedeploy: false
  labels:
    app.example.com/team: "platform"

components:
  web:
    image: "myapp-web:v1.0.0"
    replicas: 3
    containerPort: 80
    command: null
    labels:
      app.example.com/scaling: "enabled"
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    livenessProbe:
      enabled: true
      path: "/health"
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      enabled: true
      path: "/ready"
      initialDelaySeconds: 5
      periodSeconds: 5
    env:
      - name: APP_ENV
        value: "production"
    service:
      enabled: true
      type: ClusterIP
      port: 80
    ingress:
      enabled: true
      host: "app.example.com"
      path: "/"
      pathType: Prefix
      tls:
        enabled: true
        secretName: ""  # auto-generated
        issuer: "letsencrypt"
      wwwRedirect: true
      basicAuth:
        enabled: false
        username: ""
        password: ""
      fcgi:
        enabled: false
        scriptFilename: ""
      proxyBodySize: "50m"
      whitelistSourceRange: "10.0.0.0/8"
      securityPathFilter:
        enabled: true
        blockedPaths:
          - "/.git"
          - "/.env"
    pdb:
      enabled: true
      minAvailable: 1
    initContainers:
      - name: wait-for-db
        image: busybox
        command: ["sh", "-c", "until nc -z db 5432; do sleep 1; done"]
    additionalContainers: []

  worker:
    image: "myapp-worker:v1.0.0"
    replicas: 5
    command: "php artisan queue:work"
    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"

jobs:
  - name: db-migrate
    image: "myapp-web:v1.0.0"
    command: "php artisan migrate --force"
    envFromSecret: my-app-secrets
    restartPolicy: Never
    backoffLimit: 3
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"

cronJobs:
  - name: cleanup
    schedule: "0 2 * * *"
    image: "myapp-worker:v1.0.0"
    command: "php artisan cleanup"
    envFromSecret: my-app-secrets
    restartPolicy: OnFailure
    backoffLimit: 3
    concurrencyPolicy: Forbid
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullPolicy` | Image pull policy | `Always` |
| `global.envFromSecret` | Secret for environment variables | `null` |
| `global.useDatabaseCert` | Mount database certificate | `false` |
| `global.restartAfterRedeploy` | Force pod restart on deploy | `false` |
| `global.labels` | Labels for all resources | `{}` |
| `components.<name>.image` | Container image | required |
| `components.<name>.replicas` | Number of replicas | `1` |
| `components.<name>.containerPort` | Container port | `80` |
| `components.<name>.command` | Override command | `null` |
| `components.<name>.resources` | Resource limits/requests | `{}` |
| `components.<name>.service.enabled` | Create service | `false` |
| `components.<name>.ingress.enabled` | Create ingress | `false` |
| `components.<name>.ingress.host` | Ingress hostname | required |
| `components.<name>.ingress.tls.enabled` | Enable TLS | `true` |
| `components.<name>.ingress.whitelistSourceRange` | IP whitelist | `""` |
| `components.<name>.pdb.enabled` | Create PodDisruptionBudget | `false` |

---

## Adminer

Database management UI for MySQL, PostgreSQL, SQLite, MS SQL, Oracle, and others.

### Example

```yaml
image: "adminer:latest"
replicas: 1
imagePullPolicy: Always

ingress:
  enabled: true
  host: "adminer.example.com"
  tls: true
  issueCertificate: true
  clusterIssuer: "letsencrypt"
  whitelistSourceRange: "10.0.0.0/8"  # VPN only
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Container image | `adminer:latest` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `ingress.enabled` | Create ingress | `false` |
| `ingress.host` | Ingress hostname | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.issueCertificate` | Issue cert via cert-manager | `true` |
| `ingress.clusterIssuer` | Cert-manager issuer | `letsencrypt` |
| `ingress.tlsSecretName` | Custom TLS secret | `""` |
| `ingress.whitelistSourceRange` | IP whitelist | `null` |

---

## Metabase

Open source business intelligence tool for data visualization and analytics.

### Example

```yaml
image: "metabase/metabase:latest"
replicas: 1
imagePullPolicy: Always

database:
  type: "postgres"
  host: "postgres.database.svc"
  port: "5432"
  name: "metabase"
  user: "metabase"
  password: "secret"

ingress:
  enabled: true
  host: "metabase.example.com"
  tls: true
  issueCertificate: true
  clusterIssuer: "letsencrypt"
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Container image | `metabase/metabase:latest` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `database.type` | Database type (h2, postgres, mysql) | `h2` |
| `database.host` | Database host | `""` |
| `database.port` | Database port | `""` |
| `database.name` | Database name | `""` |
| `database.user` | Database user | `""` |
| `database.password` | Database password | `""` |
| `ingress.enabled` | Create ingress | `false` |
| `ingress.host` | Ingress hostname | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.issueCertificate` | Issue cert via cert-manager | `true` |
| `ingress.clusterIssuer` | Cert-manager issuer | `letsencrypt` |
| `ingress.tlsSecretName` | Custom TLS secret | `""` |

---

## n8n

Self-hosted workflow automation tool for connecting apps and automating tasks.

### Example

```yaml
image: "docker.n8n.io/n8nio/n8n"
replicas: 1
imagePullPolicy: Always
envFromSecret: n8n-secrets

ingress:
  enabled: true
  host: "n8n.example.com"
  tls: true
  issueCertificate: true
  clusterIssuer: "letsencrypt"
  whitelistSourceRange: "10.0.0.0/8"  # VPN only
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Container image | `docker.n8n.io/n8nio/n8n` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `envFromSecret` | Secret for environment variables | `null` |
| `ingress.enabled` | Create ingress | `false` |
| `ingress.host` | Ingress hostname | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.issueCertificate` | Issue cert via cert-manager | `true` |
| `ingress.clusterIssuer` | Cert-manager issuer | `letsencrypt` |
| `ingress.tlsSecretName` | Custom TLS secret | `""` |
| `ingress.whitelistSourceRange` | IP whitelist | `null` |

---

## RBAC

Role-based access control for managing user permissions across cluster namespaces.

### Example

```yaml
installRoles: true

user:
  namespace: access
  name: "developer@example.com"

access:
  allNamespaces: false
  clusterAdmin: false
  namespaceAdmin: true
  allowedNamespaces:
    - development
    - staging
```

### Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installRoles` | Install cluster roles | `false` |
| `user.namespace` | Namespace for user binding | `access` |
| `user.name` | User identifier (email) | `""` |
| `access.allNamespaces` | Access to all namespaces | `false` |
| `access.clusterAdmin` | Full cluster admin access | `false` |
| `access.namespaceAdmin` | Admin access to allowed namespaces | `false` |
| `access.allowedNamespaces` | List of accessible namespaces | `[]` |

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
