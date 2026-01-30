# RBAC Chart

**Helm chart for setting up role-based access control to Kubernetes cluster resources**

This chart creates ServiceAccounts, ClusterRoles, RoleBindings, and ClusterRoleBindings to manage access permissions for users and services in your Kubernetes cluster. It supports multiple access levels from read-only view access to full cluster administration.

## Features

- **Multiple access levels** - View, Developer, Namespace Admin, and Cluster Admin roles
- **Flexible user assignment** - Assign users to any combination of roles
- **Namespace-scoped permissions** - Control access to specific namespaces
- **Service account creation** - Create dedicated service accounts with tokens
- **Pre-defined roles** - Ready-to-use role definitions for common scenarios
- **Conditional role installation** - Optionally install cluster-wide role definitions

## Installation

```bash
helm repo add enlabs-org https://enlabs-org.github.io/charts/
helm install my-rbac enlabs-org/rbac
```

## Quick Start

### Basic User Access

```yaml
installRoles: true
user:
  name: "developer-user"
  namespace: "development"
access:
  allNamespaces: true
```

### Namespace-Specific Access

```yaml
installRoles: true
user:
  name: "frontend-team"
  namespace: "team-access"
access:
  namespaceAdmin: true
  allowedNamespaces: ["frontend-prod", "frontend-staging"]
```

### Cluster Administrator

```yaml
installRoles: true
user:
  name: "cluster-operator"
  namespace: "admin"
access:
  clusterAdmin: true
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installRoles` | Install cluster-wide role definitions | `false` |

### User Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `user.namespace` | Namespace to create the ServiceAccount in | `access` |
| `user.name` | Name of the user/ServiceAccount | `""` |

### Access Control

| Parameter | Description | Default |
|-----------|-------------|---------|
| `access.allNamespaces` | Grant access to all namespaces | `false` |
| `access.clusterAdmin` | Grant cluster administrator privileges | `false` |
| `access.namespaceAdmin` | Grant namespace administrator privileges | `false` |
| `access.allowedNamespaces` | List of specific namespaces to grant access to | `[]` |

## Access Levels

### 1. View Access (Default)

Read-only access to basic resources:
- **Resources**: pods, services, configmaps, deployments, ingresses
- **Permissions**: get, list, watch
- **Scope**: Specified namespaces or all namespaces

```yaml
user:
  name: "viewer"
access:
  allNamespaces: true
```

### 2. Developer Access

Full access to application resources but no cluster-level permissions:
- **Resources**: pods, services, configmaps, secrets, deployments, jobs, ingresses
- **Permissions**: get, list, watch, create, update, patch, delete
- **Additional**: pod exec, attach, port-forward, logs
- **Scope**: Specified namespaces

```yaml
user:
  name: "developer"
access:
  allowedNamespaces: ["development", "testing"]
```

### 3. Namespace Admin

Full control within specified namespaces:
- **Resources**: All resources within namespace scope
- **Permissions**: Full CRUD operations
- **Additional**: Can manage roles and role bindings within namespaces
- **Scope**: Specified namespaces only

```yaml
user:
  name: "team-lead"
access:
  namespaceAdmin: true
  allowedNamespaces: ["production", "staging"]
```

### 4. Cluster Admin

Full cluster-wide administrative access:
- **Resources**: All cluster resources
- **Permissions**: Complete cluster administration
- **Scope**: Entire cluster

```yaml
user:
  name: "platform-admin"
access:
  clusterAdmin: true
```

## Role Definitions

When `installRoles: true`, the chart creates these ClusterRoles:

### Developer Role

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods/exec", "pods/attach", "pods/portforward", "pods/log"]
    verbs: ["get", "list", "create"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### Namespace Admin Role

Full access to all resources within namespace scope including:
- Core API group (pods, services, configmaps, secrets)
- Apps group (deployments, replicasets, statefulsets)
- Batch group (jobs, cronjobs)
- Networking group (ingresses, network policies)
- Autoscaling group (horizontal pod autoscalers)
- Local RBAC management (roles, rolebindings)

## Examples

### Development Team Setup

```yaml
installRoles: true

user:
  name: "frontend-developers"
  namespace: "team-access"

access:
  allowedNamespaces: 
    - "frontend-dev"
    - "frontend-staging"
    - "frontend-testing"
```

### Production Team with Namespace Admin

```yaml
installRoles: true

user:
  name: "production-team"
  namespace: "prod-access"

access:
  namespaceAdmin: true
  allowedNamespaces:
    - "production"
    - "monitoring"
```

### Platform Engineering Team

```yaml
installRoles: true

user:
  name: "platform-engineers"
  namespace: "platform"

access:
  clusterAdmin: true
```

### CI/CD Service Account

```yaml
installRoles: true

user:
  name: "ci-cd-runner"
  namespace: "ci-cd"

access:
  allNamespaces: true
  allowedNamespaces: [] # This will be ignored due to allNamespaces: true
```

### Read-Only Monitoring

```yaml
installRoles: false  # Using default view permissions

user:
  name: "monitoring-agent"
  namespace: "monitoring"

access:
  allNamespaces: true
```

## Service Account Token

The chart automatically creates a ServiceAccount with a corresponding token secret. You can retrieve the token for use in CI/CD systems or kubectl configuration:

```bash
# Get the token
kubectl get secret -n <namespace> <username>-token -o jsonpath='{.data.token}' | base64 -d

# Use with kubectl
kubectl config set-credentials <username> --token=<token>
```

## Security Considerations

1. **Principle of Least Privilege** - Only grant the minimum permissions required
2. **Namespace Isolation** - Use namespace-specific access when possible
3. **Regular Auditing** - Review and rotate service account tokens regularly
4. **Role Separation** - Separate development, staging, and production access

## Testing

Test RBAC permissions:

```bash
# Check if user can list pods
kubectl auth can-i list pods --as=system:serviceaccount:<namespace>:<username>

# Check namespace-specific permissions
kubectl auth can-i create deployments --namespace=<namespace> --as=system:serviceaccount:<namespace>:<username>

# Generate manifests locally
helm template rbac-test charts/rbac/ -f values.yaml
```

## Common Use Cases

### 1. CI/CD Pipeline Access
```yaml
installRoles: true
user:
  name: "github-actions"
  namespace: "ci-cd"
access:
  allowedNamespaces: ["staging", "production"]
```

### 2. Developer Onboarding
```yaml
installRoles: true
user:
  name: "new-developer"
  namespace: "developers"
access:
  allowedNamespaces: ["development", "personal-sandbox"]
```

### 3. Monitoring and Observability
```yaml
installRoles: false  # Read-only access
user:
  name: "prometheus"
  namespace: "monitoring"
access:
  allNamespaces: true
```

## Troubleshooting

### Permission Denied Errors

1. Verify the ServiceAccount exists: `kubectl get sa -n <namespace>`
2. Check RoleBindings: `kubectl get rolebindings,clusterrolebindings --all-namespaces | grep <username>`
3. Test permissions: `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<username>`

### Role Not Found

Ensure `installRoles: true` is set if you're using the built-in developer or namespace-admin roles.

## Version History

- **1.0.1** - Current version
- **1.0.0** - Initial release