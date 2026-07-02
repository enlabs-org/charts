# n8n Chart

**Helm chart for deploying n8n workflow automation platform**

[n8n](https://n8n.io/) is a free and open-source workflow automation tool that allows you to connect different services and automate tasks without coding. This chart deploys n8n in your Kubernetes cluster with support for custom configurations and persistent storage.

## Features

- **Visual Workflow Builder** - Drag and drop interface for creating automations
- **200+ Integrations** - Connect to popular services like Slack, Gmail, GitHub, etc.
- **Code Execution** - Run custom JavaScript/Python code in workflows
- **Webhooks** - Trigger workflows via HTTP requests
- **Scheduled Execution** - Run workflows on schedules (cron-like)
- **Error Handling** - Built-in error handling and retry mechanisms
- **Multi-user Support** - Team collaboration features
- **Self-hosted** - Full control over your data and workflows
- **Automatic TLS** - Let's Encrypt certificate management

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install n8n enlabs-org/n8n
```

## Quick Start

### Basic Deployment (Internal Access)

```yaml
image: "docker.n8n.io/n8nio/n8n"
replicas: 1
```

### Public Deployment with Domain

```yaml
image: "docker.n8n.io/n8nio/n8n"
replicas: 1

ingress:
  enabled: true
  host: "automation.example.com"
  tls: true
  issueCertificate: true
```

### Secure Deployment with Configuration

```yaml
image: "docker.n8n.io/n8nio/n8n:latest"
replicas: 1
envFromSecret: "n8n-config"

ingress:
  enabled: true
  host: "workflows.company.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "10.0.0.0/8,192.168.0.0/16"
```

## Configuration

### Deployment Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | n8n image repository | `docker.n8n.io/n8nio/n8n` |
| `image.tag` | Image tag / version. Empty falls back to `Chart.appVersion` | `"latest"` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `replicas` | Number of replicas | `1` |
| `envFromSecret` | Secret name for environment variables | `null` |

#### Selecting the n8n version / channel

The chart splits image into `repository` + `tag` so you can independently pin the version and switch release channels.

```yaml
# Stable, pinned version
image:
  repository: docker.n8n.io/n8nio/n8n
  tag: "1.94.0"

# Preview / next channel
image:
  repository: docker.n8n.io/n8nio/n8n
  tag: "next"

# Rolling latest (not recommended for production)
image:
  repository: docker.n8n.io/n8nio/n8n
  tag: "latest"

# Custom mirror / fork
image:
  repository: my-registry.example.com/n8nio/n8n
  tag: "1.94.0-custom"
```

When `image.tag` is empty, the chart falls back to `Chart.appVersion` from `Chart.yaml`.

**Legacy string format** is still supported for backward compatibility:

```yaml
image: "docker.n8n.io/n8nio/n8n:1.94.0"     # used verbatim
imagePullPolicy: IfNotPresent                # top-level legacy field
```

If both formats are set, the object form wins.

### Persistence Settings

n8n stores workflows, credentials, the SQLite database (if used) and — critically — the **encryption key** in `/home/node/.n8n`. Even when you use an external Postgres/MySQL, losing this directory means losing the ability to decrypt stored credentials. **For any non-throwaway deployment enable persistence.**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Create a PVC and mount `/home/node/.n8n` | `false` |
| `persistence.size` | PVC size (ignored with `existingClaim`) | `10Gi` |
| `persistence.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.storageClassName` | StorageClass name; empty = cluster default | `null` |
| `persistence.mountPath` | Mount path inside the container | `/home/node/.n8n` |
| `persistence.existingClaim` | Use an existing PVC instead of creating one | `null` |
| `persistence.annotations` | Annotations on the created PVC | `{}` |
| `strategy` | Deployment strategy; auto-defaults to `Recreate` when persistence is enabled | `null` |

When `persistence.enabled: true` and `strategy` is unset, the chart uses `strategy.type: Recreate`. This prevents `Multi-Attach` deadlocks with `ReadWriteOnce` volumes during redeploys. Explicitly set `strategy` to override.

#### Example — DigitalOcean

```yaml
persistence:
  enabled: true
  size: 20Gi
  accessModes: [ReadWriteOnce]
  storageClassName: do-block-storage
  # strategy: Recreate is applied automatically
```

#### Example — Use existing PVC

```yaml
persistence:
  enabled: true
  existingClaim: my-preprovisioned-n8n-pvc
```

#### Migrating an existing deployment to persistent storage

**⚠️ Warning — enabling persistence on a running n8n WILL wipe its data unless you migrate manually.**

When you flip `persistence.enabled` from `false` to `true` and run `helm upgrade`:

1. The chart creates an empty PVC.
2. The Deployment strategy switches to `Recreate` (auto).
3. The old pod terminates → its ephemeral filesystem (including `/home/node/.n8n`) is gone.
4. A new pod starts, mounts the empty PVC, and n8n bootstraps fresh.

**What gets lost:**

| Setup | Data at risk |
|-------|--------------|
| SQLite (default DB) | All workflows, executions, users, credentials |
| External Postgres / MySQL | Workflows and users survive, **but the encryption key in `/home/node/.n8n/config` is lost — all encrypted credentials in the DB become unreadable** |
| Any setup | Custom node modules installed at runtime, `.n8n/nodes`, custom binary data |

**Safe migration procedure:**

```bash
# 1. Back up the current .n8n directory from the running pod
kubectl exec deploy/n8n -- tar czf - -C /home/node .n8n > n8n-backup.tar.gz

# 2. (belt & suspenders) Save the encryption key separately
kubectl exec deploy/n8n -- cat /home/node/.n8n/config | grep encryptionKey
#    → store this value in a password manager

# 3. Apply the chart with persistence enabled
helm upgrade n8n enlabs-org/n8n \
  --set persistence.enabled=true \
  --set persistence.size=20Gi \
  --set persistence.storageClassName=do-block-storage

# 4. Wait for the new pod to come up on the (empty) PVC
kubectl rollout status deploy/n8n

# 5. Restore the backup into the new pod's mounted PVC
kubectl exec -i deploy/n8n -- tar xzf - -C /home/node < n8n-backup.tar.gz

# 6. Restart n8n so it picks up the restored files
kubectl rollout restart deploy/n8n

# 7. Verify: log in, open a workflow, run a test execution
```

Downtime is ~30-60 seconds. Zero data loss.

**When you can skip migration:**

- Fresh install — nothing to lose yet.
- Test / disposable deployment with no important workflows or credentials.

**When it's OK-ish to skip but risky:**

- External DB and you're willing to re-enter every credential in every workflow (the encryption key is gone).

The chart itself does **not** copy data from ephemeral storage into the new PVC — that's a manual step by design, since the chart has no way to safely detect what's worth preserving.

### Ingress Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Hostname for ingress | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.issueCertificate` | Auto-issue certificate via cert-manager | `true` |
| `ingress.clusterIssuer` | Certificate issuer | `letsencrypt` |
| `ingress.tlsSecretName` | Custom TLS secret name | `""` |
| `ingress.whitelistSourceRange` | IP whitelist for access restriction | `null` |

## Environment Configuration

n8n supports extensive configuration through environment variables. Create a Kubernetes secret with your settings:

```bash
kubectl create secret generic n8n-config \
  --from-literal=N8N_BASIC_AUTH_ACTIVE=true \
  --from-literal=N8N_BASIC_AUTH_USER=admin \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=secure-password \
  --from-literal=N8N_HOST=workflows.company.com \
  --from-literal=N8N_PROTOCOL=https \
  --from-literal=N8N_PORT=5678 \
  --from-literal=WEBHOOK_URL=https://workflows.company.com/
```

### Common Environment Variables

#### Basic Authentication
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-password
```

#### Database Configuration
```bash
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgresql.database.svc.cluster.local
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n-password
```

#### URL Configuration
```bash
N8N_HOST=workflows.company.com
N8N_PROTOCOL=https
N8N_PORT=5678
WEBHOOK_URL=https://workflows.company.com/
```

#### Email Configuration (SMTP)
```bash
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=smtp.company.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=notifications@company.com
N8N_SMTP_PASS=smtp-password
N8N_SMTP_SENDER=n8n@company.com
```

## Deployment Examples

### Development Environment

```yaml
image: "docker.n8n.io/n8nio/n8n:latest"
replicas: 1

envFromSecret: "n8n-dev-config"

ingress:
  enabled: true
  host: "n8n.dev.example.com"
  tls: true
```

Secret for development:
```bash
kubectl create secret generic n8n-dev-config \
  --from-literal=N8N_BASIC_AUTH_ACTIVE=true \
  --from-literal=N8N_BASIC_AUTH_USER=dev \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=dev-password
```

### Production Environment

```yaml
image: "docker.n8n.io/n8nio/n8n:1.0.5"  # Pinned version
replicas: 2  # High availability

envFromSecret: "n8n-production-config"

ingress:
  enabled: true
  host: "automation.company.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "10.0.0.0/8"
```

Production secret:
```bash
kubectl create secret generic n8n-production-config \
  --from-literal=N8N_BASIC_AUTH_ACTIVE=true \
  --from-literal=N8N_BASIC_AUTH_USER=admin \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=production-secure-password \
  --from-literal=DB_TYPE=postgresdb \
  --from-literal=DB_POSTGRESDB_HOST=postgresql.database.svc.cluster.local \
  --from-literal=DB_POSTGRESDB_PORT=5432 \
  --from-literal=DB_POSTGRESDB_DATABASE=n8n_production \
  --from-literal=DB_POSTGRESDB_USER=n8n \
  --from-literal=DB_POSTGRESDB_PASSWORD=db-secure-password \
  --from-literal=WEBHOOK_URL=https://automation.company.com/
```

### Team Deployment with User Management

```yaml
image: "docker.n8n.io/n8nio/n8n:latest"
replicas: 1

envFromSecret: "n8n-team-config"

ingress:
  enabled: true
  host: "workflows.team.company.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "192.168.1.0/24"
```

Team configuration:
```bash
kubectl create secret generic n8n-team-config \
  --from-literal=N8N_USER_MANAGEMENT_DISABLED=false \
  --from-literal=N8N_EMAIL_MODE=smtp \
  --from-literal=N8N_SMTP_HOST=smtp.company.com \
  --from-literal=N8N_SMTP_PORT=587 \
  --from-literal=N8N_SMTP_USER=n8n@company.com \
  --from-literal=N8N_SMTP_PASS=smtp-password
```

## Database Setup

### SQLite (Default)

n8n uses SQLite by default, which stores data in a file within the container. This is suitable for development but not recommended for production.

### PostgreSQL (Recommended for Production)

Create database and user:

```sql
CREATE DATABASE n8n;
CREATE USER n8n WITH PASSWORD 'secure-password';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
```

Configure via secret:
```bash
kubectl create secret generic n8n-db-config \
  --from-literal=DB_TYPE=postgresdb \
  --from-literal=DB_POSTGRESDB_HOST=postgresql.database.svc.cluster.local \
  --from-literal=DB_POSTGRESDB_PORT=5432 \
  --from-literal=DB_POSTGRESDB_DATABASE=n8n \
  --from-literal=DB_POSTGRESDB_USER=n8n \
  --from-literal=DB_POSTGRESDB_PASSWORD=secure-password
```

### MySQL

Create database and user:
```sql
CREATE DATABASE n8n CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'n8n'@'%' IDENTIFIED BY 'secure-password';
GRANT ALL PRIVILEGES ON n8n.* TO 'n8n'@'%';
```

Configure via secret:
```bash
kubectl create secret generic n8n-db-config \
  --from-literal=DB_TYPE=mysqldb \
  --from-literal=DB_MYSQLDB_HOST=mysql.database.svc.cluster.local \
  --from-literal=DB_MYSQLDB_PORT=3306 \
  --from-literal=DB_MYSQLDB_DATABASE=n8n \
  --from-literal=DB_MYSQLDB_USER=n8n \
  --from-literal=DB_MYSQLDB_PASSWORD=secure-password
```

## Security Configuration

### IP Whitelisting

Restrict access to your network:

```yaml
ingress:
  enabled: true
  whitelistSourceRange: "10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
```

### Basic Authentication

Enable basic auth protection:

```bash
kubectl create secret generic n8n-auth \
  --from-literal=N8N_BASIC_AUTH_ACTIVE=true \
  --from-literal=N8N_BASIC_AUTH_USER=your-username \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=your-secure-password
```

### User Management

For team environments, enable user management:

```bash
kubectl create secret generic n8n-users \
  --from-literal=N8N_USER_MANAGEMENT_DISABLED=false \
  --from-literal=N8N_USER_MANAGEMENT_JWT_SECRET=jwt-secret-key
```

## Common Use Cases

### API Integration Workflows

```yaml
# Automate API integrations between services
envFromSecret: "n8n-api-config"
ingress:
  enabled: true
  host: "api-automation.company.com"
```

### Data Processing Pipeline

```yaml
# Process and transform data between systems
envFromSecret: "n8n-data-config"
ingress:
  enabled: true
  host: "data-workflows.company.com"
```

### Notification and Alerting

```yaml
# Send notifications based on events
envFromSecret: "n8n-notifications-config"
```

Example notification workflow configuration:
```bash
kubectl create secret generic n8n-notifications-config \
  --from-literal=N8N_BASIC_AUTH_ACTIVE=true \
  --from-literal=N8N_BASIC_AUTH_USER=notifications \
  --from-literal=N8N_BASIC_AUTH_PASSWORD=notify-password \
  --from-literal=WEBHOOK_URL=https://notifications.company.com/
```

## Workflow Examples

### Slack Integration

Create workflows that:
- Monitor GitHub for new issues and post to Slack
- Send daily reports to team channels
- Alert on deployment failures

### Data Synchronization

Automate data sync between:
- CRM systems and databases
- Spreadsheets and applications
- Cloud services and local systems

### Content Management

Automate:
- Social media posting
- Content approval workflows
- Asset management tasks

## Monitoring and Maintenance

### Health Checks

```bash
# Check n8n pod status
kubectl get pods -l app=n8n

# Check service
kubectl get service n8n

# Test application
curl -I https://workflows.company.com/healthz
```

### Logs

```bash
# View n8n logs
kubectl logs -l app=n8n -f

# Check workflow execution logs through the UI
```

### Backup

For production deployments:
1. **Database backup** - Regular PostgreSQL/MySQL backups
2. **Workflow export** - Export workflows from n8n UI
3. **Configuration backup** - Backup Kubernetes secrets

## Troubleshooting

### Webhook Issues

1. **Check WEBHOOK_URL** configuration
2. **Verify ingress** is properly configured
3. **Test webhook endpoints**:
   ```bash
   curl -X POST https://workflows.company.com/webhook-test/your-webhook-id
   ```

### Database Connection Issues

1. **Test database connectivity**:
   ```bash
   kubectl run test-db --image=postgres:alpine --rm -it -- psql -h database-host -U n8n -d n8n
   ```

2. **Check database credentials** in secret
3. **Verify network policies**

### Authentication Problems

1. **Check basic auth** credentials
2. **Verify user management** configuration
3. **Test login** through the web interface

### Performance Issues

1. **Increase resources**:
   ```yaml
   resources:
     requests:
       cpu: "500m"
       memory: "512Mi"
     limits:
       cpu: "2"
       memory: "2Gi"
   ```

2. **Scale horizontally** for high-availability
3. **Optimize workflows** for better performance

## Advanced Configuration

### Custom Node Modules

Install additional npm packages:

```bash
kubectl create secret generic n8n-custom-config \
  --from-literal=N8N_CUSTOM_EXTENSIONS=package1,package2
```

### Timezone Configuration

```bash
kubectl create secret generic n8n-timezone \
  --from-literal=TZ=America/New_York
```

### File Storage

For file handling workflows, enable persistence (see [Persistence Settings](#persistence-settings)):

```yaml
persistence:
  enabled: true
  size: 50Gi
  storageClassName: standard
```

## Integration Examples

### Popular Integrations

- **Slack** - Team notifications and bot interactions
- **Gmail** - Email automation and processing
- **GitHub** - Repository management and CI/CD triggers
- **Trello/Asana** - Project management automation
- **Google Sheets** - Data processing and reporting
- **Webhook** - Custom service integrations
- **HTTP Request** - API calls and integrations
- **Cron** - Scheduled task execution

## Version History

- **1.2.0** - Split `image` into `image.repository` + `image.tag` + `image.pullPolicy` (legacy string form still supported); introduced `Chart.appVersion` as default tag
- **1.1.0** - Added optional PersistentVolumeClaim support for `/home/node/.n8n`, with auto-`Recreate` strategy on RWO
- **1.0.0** - Initial release

## Related Tools

- [Zapier](https://zapier.com/) - Commercial automation platform
- [Microsoft Power Automate](https://powerautomate.microsoft.com/) - Microsoft's automation solution
- [Apache Airflow](https://airflow.apache.org/) - Workflow orchestration platform
- [Temporal](https://temporal.io/) - Developer-focused workflow engine