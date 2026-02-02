# K8s PWA Dashboard Chart

**Helm chart for deploying K8s Preview App Dashboard**

[K8s PWA Dashboard](https://github.com/enlabs-org/k8s-pwa-dashboard) is a simple web dashboard for monitoring and scaling Kubernetes deployments. It provides a clean interface to view deployment status across namespaces and quickly start/stop applications by scaling replicas.

## Features

- **Dynamic namespace discovery** - Automatically shows all namespaces except those in blacklist
- **Deployment status monitoring** - Running, error, pending, and stopped states
- **Start/Stop scaling** - Scale deployments to 0 or 1 replica with one click
- **Ingress URL extraction** - Displays URLs from Ingress resources
- **Auto-refresh** - Polling every 5 seconds (configurable)
- **Collapse/Expand** - Organize view by namespace
- **IP whitelisting** - Restrict access to specific IP ranges
- **Automatic TLS** - Let's Encrypt certificate management

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install k8s-pwa-dashboard enlabs-org/k8s-pwa-dashboard -n k8s-pwa-dashboard --create-namespace
```

## Quick Start

### Basic Deployment (Internal Access Only)

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:latest
replicas: 1

config:
  excludeNamespaces:
    - kube-system
    - kube-public
    - default
```

### Public Deployment with Domain

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:latest
replicas: 1

ingress:
  enabled: true
  host: "k8s-dashboard.example.com"
  tls: true
  clusterIssuer: "letsencrypt"

config:
  excludeNamespaces:
    - kube-system
    - kube-public
    - default
```

### Secure Deployment with IP Restrictions

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:latest
replicas: 1

ingress:
  enabled: true
  host: "k8s-dashboard.company.com"
  tls: true
  clusterIssuer: "letsencrypt"
  whitelistSourceRange: "10.0.0.0/8,192.168.1.0/24"

config:
  excludeNamespaces:
    - kube-system
    - kube-public
    - kube-node-lease
    - default
  pollingInterval: 10000
  scalingEnabled: true
```

## Configuration

### Image Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image` | Dashboard container image | `ghcr.io/enlabs-org/k8s-pwa-dashboard:latest` |
| `imagePullPolicy` | Image pull policy | `Always` |
| `replicas` | Number of replicas | `1` |

### Service Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `servicePort` | Service port | `80` |
| `containerPort` | Container port | `3001` |

### Ingress Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Hostname for ingress | `""` |
| `ingress.tls` | Enable TLS | `true` |
| `ingress.clusterIssuer` | Certificate issuer | `letsencrypt` |
| `ingress.whitelistSourceRange` | IP whitelist for access restriction | `""` |

### Dashboard Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.excludeNamespaces` | Namespaces to hide from dashboard | `[kube-system, kube-public, kube-node-lease, default]` |
| `config.pollingInterval` | Auto-refresh interval in milliseconds | `5000` |
| `config.scalingEnabled` | Enable Start/Stop buttons | `true` |

## RBAC Permissions

The chart automatically creates a ServiceAccount with ClusterRole permissions to:

- **Deployments**: `get`, `list`, `watch`
- **Deployments/scale**: `get`, `patch`, `update`
- **Namespaces**: `get`, `list`
- **Ingresses**: `get`, `list`

These permissions are required for the dashboard to monitor and scale deployments across all namespaces.

## Security Configuration

### IP Whitelisting

Restrict access to specific IP ranges for enhanced security:

```yaml
ingress:
  enabled: true
  host: "k8s-dashboard.internal.company.com"
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
  host: "k8s-dashboard-vpn.company.com"
  whitelistSourceRange: "10.8.0.0/24"  # VPN subnet
```

## Deployment Examples

### Development Environment

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:latest
replicas: 1

ingress:
  enabled: true
  host: "k8s-dashboard.dev.example.com"
  tls: true
  whitelistSourceRange: "192.168.1.0/24"

config:
  excludeNamespaces:
    - kube-system
  pollingInterval: 3000
  scalingEnabled: true
```

### Production Environment

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:v1.0.0  # Pinned version
replicas: 1

ingress:
  enabled: true
  host: "k8s-dashboard.company.com"
  tls: true
  whitelistSourceRange: "10.0.0.0/8"

config:
  excludeNamespaces:
    - kube-system
    - kube-public
    - kube-node-lease
    - default
    - monitoring
    - cert-manager
  pollingInterval: 10000
  scalingEnabled: true
```

### Internal Tool (No Public Access)

```yaml
image: ghcr.io/enlabs-org/k8s-pwa-dashboard:latest
replicas: 1

ingress:
  enabled: false

config:
  excludeNamespaces:
    - kube-system
```

Access via port forwarding:
```bash
kubectl port-forward -n k8s-pwa-dashboard svc/k8s-pwa-dashboard 8080:80
# Access at http://localhost:8080
```

## Usage

### Dashboard Interface

The dashboard displays:

1. **Namespace sections** - Collapsible groups for each namespace
2. **Deployment cards** - Status, replica count, and ingress URLs
3. **Status indicators**:
   - 🟢 **Running** - All replicas ready
   - 🟡 **Pending** - Deployment starting up
   - 🔴 **Error** - Deployment has issues
   - ⚪ **Stopped** - Scaled to zero

### Scaling Deployments

- Click **Stop** to scale a deployment to 0 replicas
- Click **Start** to scale a deployment to 1 replica
- Changes are reflected immediately with optimistic updates

### Excluding Namespaces

Configure which namespaces to hide:

```yaml
config:
  excludeNamespaces:
    - kube-system      # System components
    - kube-public      # Public resources
    - kube-node-lease  # Node heartbeats
    - default          # Default namespace
    - monitoring       # Monitoring stack
    - ingress-nginx    # Ingress controller
```

## Troubleshooting

### Dashboard Not Loading

1. **Check pod status**:
   ```bash
   kubectl get pods -n k8s-pwa-dashboard
   kubectl logs -n k8s-pwa-dashboard -l app.kubernetes.io/name=k8s-pwa-dashboard
   ```

2. **Verify RBAC permissions**:
   ```bash
   kubectl auth can-i list deployments --as=system:serviceaccount:k8s-pwa-dashboard:k8s-pwa-dashboard
   ```

### Cannot Scale Deployments

1. **Check ClusterRole permissions**:
   ```bash
   kubectl describe clusterrole k8s-pwa-dashboard
   ```

2. **Verify ServiceAccount binding**:
   ```bash
   kubectl describe clusterrolebinding k8s-pwa-dashboard
   ```

### IP Whitelist Issues

1. **Check your public IP**:
   ```bash
   curl ipinfo.io/ip
   ```

2. **Verify ingress annotations**:
   ```bash
   kubectl describe ingress -n k8s-pwa-dashboard k8s-pwa-dashboard
   ```

### TLS Certificate Problems

1. **Check certificate status**:
   ```bash
   kubectl get certificate -n k8s-pwa-dashboard
   kubectl describe certificate -n k8s-pwa-dashboard k8s-pwa-dashboard-tls
   ```

## Health Checks

The dashboard exposes health endpoints:

- **Liveness**: `/api/v1/health` - Checks if the application is running
- **Readiness**: `/api/v1/health` - Checks if the application is ready to serve traffic

## Monitoring

### Log Monitoring

```bash
# View dashboard logs
kubectl logs -n k8s-pwa-dashboard -l app.kubernetes.io/name=k8s-pwa-dashboard -f

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep k8s-dashboard
```

### Health Checks

```bash
# Check pod status
kubectl get pods -n k8s-pwa-dashboard

# Check service
kubectl get svc -n k8s-pwa-dashboard

# Test connectivity
curl -I https://k8s-dashboard.example.com/api/v1/health
```

## Security Best Practices

1. **Always use IP whitelisting** in production environments
2. **Use specific image tags** instead of `latest` for production
3. **Enable TLS** for all public deployments
4. **Limit namespace access** - exclude sensitive namespaces from view
5. **Consider VPN access** for sensitive environments
6. **Disable scaling** if view-only access is needed (`scalingEnabled: false`)

## Version History

- **1.0.0** - Initial release

## Related Resources

- [K8s PWA Dashboard GitHub](https://github.com/enlabs-org/k8s-pwa-dashboard)
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) - Official K8s dashboard
