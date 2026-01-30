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
| `image` | n8n container image | `docker.n8n.io/n8nio/n8n` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `envFromSecret` | Secret name for environment variables | `null` |

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

For file handling workflows:

```yaml
# Add persistent volume for file storage
persistence:
  enabled: true
  size: "50Gi"
  storageClass: "standard"
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

- **1.0.0** - Initial release

## Related Tools

- [Zapier](https://zapier.com/) - Commercial automation platform
- [Microsoft Power Automate](https://powerautomate.microsoft.com/) - Microsoft's automation solution
- [Apache Airflow](https://airflow.apache.org/) - Workflow orchestration platform
- [Temporal](https://temporal.io/) - Developer-focused workflow engine