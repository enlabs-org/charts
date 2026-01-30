# Adminer Chart

**Helm chart for deploying Adminer database management tool**

[Adminer](https://www.adminer.org/) is a full-featured database management tool written in PHP. This chart deploys Adminer as a web-based interface for managing your databases including MySQL, PostgreSQL, SQLite, MS SQL, Oracle, Firebird, SimpleDB, Elasticsearch, and MongoDB.

## Features

- **Multi-database support** - MySQL, PostgreSQL, SQLite, MS SQL, Oracle, and more
- **Web-based interface** - No client installation required
- **Lightweight** - Single PHP file application
- **Security features** - IP whitelisting and TLS support
- **Automatic TLS** - Let's Encrypt certificate management
- **Kubernetes native** - Deployment, Service, and Ingress resources

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install adminer enlabs-org/adminer
```

## Quick Start

### Basic Deployment (Internal Access Only)

```yaml
# Adminer will be available within the cluster only
image: "adminer:latest"
replicas: 1
```

### Public Deployment with Domain

```yaml
image: "adminer:latest"
replicas: 1

ingress:
  enabled: true
  host: "adminer.example.com"
  tls: true
  issueCertificate: true
```

### Secure Deployment with IP Restrictions

```yaml
image: "adminer:latest"
replicas: 1

ingress:
  enabled: true
  host: "db-admin.company.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "10.0.0.0/8,192.168.1.0/24"
```

## Configuration

### Deployment Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Adminer container image | `adminer:latest` |
| `replicas` | Number of replicas | `1` |
| `imagePullPolicy` | Image pull policy | `Always` |

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

## Usage

### Accessing Adminer

Once deployed, Adminer provides a web interface where you can:

1. **Select Database System** - Choose from MySQL, PostgreSQL, etc.
2. **Enter Connection Details**:
   - **Server**: Database hostname/IP
   - **Username**: Database username
   - **Password**: Database password
   - **Database**: Database name (optional)

### Example Database Connections

#### MySQL Connection
```
Server: mysql.database.svc.cluster.local:3306
Username: root
Password: [your-mysql-root-password]
Database: myapp_production
```

#### PostgreSQL Connection
```
Server: postgresql.database.svc.cluster.local:5432
Username: postgres
Password: [your-postgres-password]
Database: myapp_production
```

## Security Configuration

### IP Whitelisting

Restrict access to specific IP ranges for enhanced security:

```yaml
ingress:
  enabled: true
  host: "adminer.internal.company.com"
  whitelistSourceRange: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
```

Common IP ranges:
- `10.0.0.0/8` - Private class A networks
- `172.16.0.0/12` - Private class B networks  
- `192.168.0.0/16` - Private class C networks
- `203.0.113.0/24` - Your office public IP range

### VPN-Only Access

```yaml
ingress:
  enabled: true
  host: "adminer-vpn.company.com"
  whitelistSourceRange: "10.8.0.0/24"  # VPN subnet
```

### Multiple IP Ranges

```yaml
ingress:
  whitelistSourceRange: "10.0.0.0/8,192.168.1.100,203.0.113.0/24"
```

## Deployment Examples

### Development Environment

```yaml
image: "adminer:latest"
replicas: 1

ingress:
  enabled: true
  host: "adminer.dev.example.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "192.168.1.0/24"  # Local network only
```

### Production Environment

```yaml
image: "adminer:4.8.1"  # Pinned version for stability
replicas: 2  # High availability

ingress:
  enabled: true
  host: "db-admin.company.com"
  tls: true
  issueCertificate: true
  whitelistSourceRange: "10.0.0.0/8"  # Corporate network only
```

### Internal Tool (No Public Access)

```yaml
# No ingress configuration - access via port-forward only
image: "adminer:latest"
replicas: 1

ingress:
  enabled: false
```

Access via port forwarding:
```bash
kubectl port-forward deployment/adminer 8080:8080
# Access at http://localhost:8080
```

## Database Connection Examples

### Kubernetes Service Names

When your databases are running in the same Kubernetes cluster:

```yaml
# MySQL in 'database' namespace
Server: mysql.database.svc.cluster.local
Port: 3306

# PostgreSQL in same namespace  
Server: postgresql.default.svc.cluster.local
Port: 5432

# External database
Server: db.company.com
Port: 5432
```

### Using Secrets for Credentials

While Adminer requires manual entry of credentials, you can prepare the information:

```bash
# Get database credentials from secrets
kubectl get secret mysql-credentials -o jsonpath='{.data.username}' | base64 -d
kubectl get secret mysql-credentials -o jsonpath='{.data.password}' | base64 -d
```

## Advanced Configuration

### Custom Adminer Image

For specific database support or plugins:

```yaml
image: "adminer:4.8.1-standalone"  # No external dependencies
# or
image: "adminer:fastcgi"  # For use with nginx
```

### Resource Limits

```yaml
# Add to deployment template if needed
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

## Supported Databases

Adminer supports connecting to:

- **MySQL** - Most common use case
- **PostgreSQL** - Full support including arrays and JSON
- **SQLite** - File-based databases
- **MS SQL** - Microsoft SQL Server
- **Oracle** - Enterprise databases
- **MongoDB** - NoSQL document databases
- **Elasticsearch** - Search engine databases
- **Firebird** - Open source SQL database
- **SimpleDB** - Amazon's NoSQL service

## Security Best Practices

1. **Always use IP whitelisting** in production environments
2. **Use specific image tags** instead of `latest` for production
3. **Enable TLS** for all public deployments
4. **Limit database user permissions** - create read-only users when possible
5. **Monitor access logs** for suspicious activity
6. **Consider VPN access** for sensitive environments

## Troubleshooting

### Cannot Connect to Database

1. **Check network connectivity**:
   ```bash
   kubectl exec -it adminer-pod -- nc -zv database-host 5432
   ```

2. **Verify service names**:
   ```bash
   kubectl get services -A | grep database
   ```

3. **Test credentials manually**:
   ```bash
   kubectl run test-db --image=postgres:alpine --rm -it -- psql -h database-host -U username
   ```

### IP Whitelist Issues

1. **Check your public IP**:
   ```bash
   curl ipinfo.io/ip
   ```

2. **Verify NGINX ingress annotations**:
   ```bash
   kubectl describe ingress adminer
   ```

### TLS Certificate Problems

1. **Check certificate status**:
   ```bash
   kubectl get certificate
   kubectl describe certificate adminer-tls
   ```

## Monitoring and Maintenance

### Health Checks

```bash
# Check pod status
kubectl get pods -l app=adminer

# Check ingress
kubectl get ingress adminer

# Test connectivity
curl -I https://adminer.example.com
```

### Log Monitoring

```bash
# View Adminer logs
kubectl logs -l app=adminer -f

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Version History

- **1.0.0** - Initial release

## Related Tools

- [phpMyAdmin](https://www.phpmyadmin.net/) - MySQL-specific alternative
- [pgAdmin](https://www.pgadmin.org/) - PostgreSQL-specific alternative  
- [MongoDB Compass](https://www.mongodb.com/products/compass) - MongoDB GUI