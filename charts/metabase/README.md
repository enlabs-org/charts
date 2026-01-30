# Metabase Chart

**Helm chart for deploying Metabase business intelligence and analytics platform**

[Metabase](https://www.metabase.com/) is an open-source business intelligence tool that lets you create dashboards and ask questions about your data without requiring SQL knowledge. This chart deploys Metabase in your Kubernetes cluster with support for external databases and persistent storage.

## Features

- **Business Intelligence Dashboard** - Create charts, graphs, and dashboards from your data
- **Question Builder** - Visual query builder for non-technical users
- **SQL Editor** - Direct SQL query support for advanced users
- **Multiple Database Support** - Connect to MySQL, PostgreSQL, MongoDB, and more
- **User Management** - Built-in authentication and authorization
- **Embedding** - Embed charts and dashboards in other applications
- **Automatic TLS** - Let's Encrypt certificate management
- **Configurable Storage** - H2 (default) or external database for metadata

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install metabase enlabs-org/metabase
```

## Quick Start

### Basic Deployment (H2 Database)

```yaml
image: "metabase/metabase:latest"
replicas: 1

database:
  type: "h2"  # Built-in H2 database for quick setup

ingress:
  enabled: true
  host: "analytics.example.com"
```

### Production Deployment (PostgreSQL)

```yaml
image: "metabase/metabase:v0.48.0"  # Pinned version
replicas: 2

database:
  type: "postgres"
  host: "postgresql.database.svc.cluster.local"
  port: "5432"
  name: "metabase"
  user: "metabase"
  password: "secure-password"

ingress:
  enabled: true
  host: "analytics.company.com"
  tls: true
  issueCertificate: true
```

### High Availability Setup

```yaml
image: "metabase/metabase:v0.48.0"
replicas: 3

database:
  type: "mysql"
  host: "mysql.database.svc.cluster.local"
  port: "3306"
  name: "metabase_prod"
  user: "metabase_user"
  password: "production-password"

ingress:
  enabled: true
  host: "bi.company.com"
  tls: true
  issueCertificate: true
```

## Configuration

### Deployment Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Metabase container image | `metabase/metabase:latest` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.type` | Database type (h2, postgres, mysql) | `h2` |
| `database.host` | Database hostname | `""` |
| `database.port` | Database port | `""` |
| `database.name` | Database name | `""` |
| `database.user` | Database username | `""` |
| `database.password` | Database password | `""` |

### Ingress Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Hostname for ingress | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.issueCertificate` | Auto-issue certificate via cert-manager | `true` |
| `ingress.clusterIssuer` | Certificate issuer | `letsencrypt` |
| `ingress.tlsSecretName` | Custom TLS secret name | `""` |

## Database Setup

### H2 (Default - Development Only)

H2 is an embedded database perfect for development and testing:

```yaml
database:
  type: "h2"
```

⚠️ **Warning**: H2 database is not suitable for production as data is stored in the container and will be lost when the pod restarts.

### PostgreSQL (Recommended for Production)

First, create the Metabase database and user:

```sql
CREATE DATABASE metabase;
CREATE USER metabase WITH PASSWORD 'secure-password';
GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase;
```

Then configure the chart:

```yaml
database:
  type: "postgres"
  host: "postgresql.database.svc.cluster.local"
  port: "5432"
  name: "metabase"
  user: "metabase"
  password: "secure-password"
```

### MySQL

Create the database and user:

```sql
CREATE DATABASE metabase CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'metabase'@'%' IDENTIFIED BY 'secure-password';
GRANT ALL PRIVILEGES ON metabase.* TO 'metabase'@'%';
FLUSH PRIVILEGES;
```

Configure the chart:

```yaml
database:
  type: "mysql"
  host: "mysql.database.svc.cluster.local"
  port: "3306"
  name: "metabase"
  user: "metabase"
  password: "secure-password"
```

## Deployment Examples

### Development Environment

```yaml
image: "metabase/metabase:latest"
replicas: 1

database:
  type: "h2"

ingress:
  enabled: true
  host: "metabase.dev.example.com"
  tls: true
```

### Staging Environment

```yaml
image: "metabase/metabase:v0.48.0"
replicas: 1

database:
  type: "postgres"
  host: "staging-db.company.com"
  port: "5432"
  name: "metabase_staging"
  user: "metabase"
  password: "staging-password"

ingress:
  enabled: true
  host: "analytics.staging.company.com"
  tls: true
  issueCertificate: true
```

### Production Environment

```yaml
image: "metabase/metabase:v0.48.0"
replicas: 3

database:
  type: "postgres"
  host: "production-db.company.com"
  port: "5432"
  name: "metabase_production"
  user: "metabase_prod"
  password: "production-secure-password"

ingress:
  enabled: true
  host: "analytics.company.com"
  tls: true
  issueCertificate: true
  clusterIssuer: "letsencrypt-prod"
```

## Initial Setup

### First Time Configuration

1. **Access Metabase** at your configured domain
2. **Create Admin Account** - Set up the first admin user
3. **Connect to Data** - Add your business databases
4. **Configure Email** (Optional) - For sharing and alerts

### Adding Data Sources

Common data source configurations:

#### PostgreSQL Data Source
```
Host: postgresql.app.svc.cluster.local
Port: 5432
Database name: myapp_production
Username: readonly_user
Password: [readonly-password]
```

#### MySQL Data Source
```
Host: mysql.app.svc.cluster.local
Port: 3306
Database name: myapp_production
Username: analytics_user
Password: [analytics-password]
```

#### MongoDB Data Source
```
Host: mongodb.app.svc.cluster.local
Port: 27017
Database name: myapp_production
Username: metabase_user
Password: [mongo-password]
```

## Security Configuration

### Database Credentials

Store sensitive database credentials in Kubernetes secrets:

```bash
kubectl create secret generic metabase-db-credentials \
  --from-literal=username=metabase \
  --from-literal=password=secure-password
```

### Read-Only Database Users

Create dedicated read-only users for Metabase to connect to your application databases:

```sql
-- PostgreSQL
CREATE USER metabase_readonly WITH PASSWORD 'readonly-password';
GRANT CONNECT ON DATABASE myapp_production TO metabase_readonly;
GRANT USAGE ON SCHEMA public TO metabase_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO metabase_readonly;

-- MySQL
CREATE USER 'metabase_readonly'@'%' IDENTIFIED BY 'readonly-password';
GRANT SELECT ON myapp_production.* TO 'metabase_readonly'@'%';
```

## Advanced Configuration

### Environment Variables

Add custom environment variables to the deployment:

```yaml
# These would need to be added to the deployment template
env:
  - name: MB_EMAIL_SMTP_HOST
    value: "smtp.company.com"
  - name: MB_EMAIL_SMTP_PORT
    value: "587"
  - name: MB_EMAIL_SMTP_SECURITY
    value: "tls"
  - name: MB_SITE_URL
    value: "https://analytics.company.com"
```

### Persistent Storage

For H2 database persistence (development only):

```yaml
# Add persistent volume claim to deployment
persistence:
  enabled: true
  storageClass: "standard"
  size: "10Gi"
```

### Resource Requirements

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2"
```

## Common Use Cases

### Marketing Analytics

```yaml
# Marketing team analytics dashboard
image: "metabase/metabase:v0.48.0"
replicas: 2

database:
  type: "postgres"
  host: "analytics-db.marketing.svc.cluster.local"
  name: "marketing_data"

ingress:
  enabled: true
  host: "marketing-analytics.company.com"
```

### Sales Dashboard

```yaml
# Sales performance tracking
database:
  type: "mysql"
  host: "crm-db.sales.svc.cluster.local"
  name: "sales_data"

ingress:
  enabled: true
  host: "sales-dashboard.company.com"
```

### Executive Reporting

```yaml
# High-level executive dashboards
image: "metabase/metabase:v0.48.0"
replicas: 1

database:
  type: "postgres"
  host: "datawarehouse.company.com"
  name: "executive_reporting"

ingress:
  enabled: true
  host: "executive-dashboard.company.com"
```

## Maintenance and Monitoring

### Health Checks

```bash
# Check Metabase pod status
kubectl get pods -l app=metabase

# Check service
kubectl get service metabase

# Test application
curl -I https://analytics.example.com/api/health
```

### Backup Considerations

- **H2 Database**: Backup the data volume
- **External Database**: Use standard database backup procedures
- **Configuration**: Export dashboards and questions regularly

### Updates

```bash
# Update to newer version
helm upgrade metabase enlabs-org/metabase --set image=metabase/metabase:v0.49.0
```

## Troubleshooting

### Cannot Connect to Database

1. **Test database connectivity**:
   ```bash
   kubectl run test-db --image=postgres:alpine --rm -it -- psql -h database-host -U username -d database-name
   ```

2. **Check network policies** that might block connections

3. **Verify credentials** and permissions

### Performance Issues

1. **Increase memory allocation**:
   ```yaml
   env:
     - name: JAVA_OPTS
       value: "-Xmx2g"
   ```

2. **Database optimization** - Add indexes for frequently queried columns

3. **Scale horizontally** - Increase replicas

### Login Issues

1. **Check admin user creation** during initial setup
2. **Verify email configuration** for password resets
3. **Check application logs**:
   ```bash
   kubectl logs -l app=metabase -f
   ```

## Supported Data Sources

Metabase can connect to:

- **PostgreSQL** - Full support with arrays and JSON
- **MySQL/MariaDB** - Complete compatibility
- **MongoDB** - NoSQL document databases
- **SQLite** - File-based databases
- **BigQuery** - Google's data warehouse
- **Snowflake** - Cloud data platform
- **Redshift** - Amazon's data warehouse
- **SQL Server** - Microsoft databases
- **Oracle** - Enterprise databases

## Version History

- **1.0.2** - Current version
- **1.0.0** - Initial release

## Related Tools

- [Grafana](https://grafana.com/) - Monitoring and observability
- [Apache Superset](https://superset.apache.org/) - Alternative BI platform
- [Looker](https://looker.com/) - Commercial BI platform