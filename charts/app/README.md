# App Chart

**Modern multi-component Helm chart for application deployments (recommended)**

This is the recommended chart for deploying applications with multiple components. It replaces the legacy `stable-app` and `preview-app` charts with a more flexible architecture that supports multiple deployments per release.

## Features

- **Multi-component architecture** - Deploy multiple services (web, worker, scheduler) in a single release
- **Auto-service creation** - Services are automatically created when `containerPort` or `ingress.enabled` is defined
- **Global defaults** - Set common values like `image` and `host` globally, with per-component overrides
- **Pod scheduling control** - Node affinity, pod affinity, and pod anti-affinity with simplified shortcuts
- **Security features** - IP whitelisting, security path filters, basic auth support, pod/container `securityContext`
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
| `global.securityPathFilter.enabled` | Enable security path filter for all components | `false` |
| `global.securityPathFilter.blockedPaths` | Default blocked paths for all components | `[]` |

### Component Configuration

Each component supports the following configuration:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable this component | `true` |
| `image` | Container image (overrides global.image) | Uses global.image |
| `replicas` | Number of replicas | `1` |
| `strategy` | Deployment strategy (full Kubernetes syntax) | Kubernetes default |
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
| `ingress.securityPathFilter.enabled` | Block sensitive paths (overrides global) | `false` |
| `ingress.securityPathFilter.blockedPaths` | Array of blocked paths (overrides global) | `[]` |

### Deployment Strategy

Control how rolling updates are performed. Useful when combined with pod anti-affinity or topology spread constraints:

```yaml
components:
  web:
    replicas: 2
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 1
        maxSurge: 0
    affinity:
      podAntiAffinity:
        requiredSpreadBy: ["kubernetes.io/hostname"]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `strategy.type` | Strategy type (`RollingUpdate` or `Recreate`) | `RollingUpdate` |
| `strategy.rollingUpdate.maxUnavailable` | Max unavailable pods during update | `25%` |
| `strategy.rollingUpdate.maxSurge` | Max extra pods during update | `25%` |

### Pod Disruption Budget

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pdb.enabled` | Enable PDB | `false` |
| `pdb.minAvailable` | Minimum available pods | `1` |

### Affinity Configuration

Control pod scheduling with Kubernetes affinity rules. The chart supports both simplified shortcuts (for common use cases) and full Kubernetes syntax (for advanced scenarios).

#### Node Affinity

Target specific nodes based on labels:

| Parameter | Description | Type |
|-----------|-------------|------|
| `affinity.nodeAffinity.preferredNodeLabels` | Soft constraint - prefer nodes with these labels | `{}` |
| `affinity.nodeAffinity.requiredNodeLabels` | Hard constraint - require nodes with these labels | `{}` |
| `affinity.nodeAffinity.custom` | Full Kubernetes nodeAffinity syntax | `{}` |

**Example - GPU workloads:**
```yaml
components:
  ml-worker:
    affinity:
      nodeAffinity:
        requiredNodeLabels:
          accelerator: gpu
        preferredNodeLabels:
          disktype: ssd
```

#### Pod Anti-Affinity

Spread pods apart for high availability or avoid resource contention:

| Parameter | Description | Type |
|-----------|-------------|------|
| `affinity.podAntiAffinity.preferredSpreadBy` | Soft constraint - spread across topology domains | `[]` |
| `affinity.podAntiAffinity.requiredSpreadBy` | Hard constraint - must spread across topology domains | `[]` |
| `affinity.podAntiAffinity.avoidComponents` | Soft constraint - avoid other components | `[]` |
| `affinity.podAntiAffinity.custom` | Full Kubernetes podAntiAffinity syntax | `{}` |

**Example - High availability:**
```yaml
components:
  web:
    replicas: 3
    affinity:
      podAntiAffinity:
        # Hard: must be on different nodes
        requiredSpreadBy: ["kubernetes.io/hostname"]
        # Soft: prefer different zones
        preferredSpreadBy: ["topology.kubernetes.io/zone"]
```

**Example - Avoid resource contention:**
```yaml
components:
  worker:
    affinity:
      podAntiAffinity:
        avoidComponents: ["heavy-batch-job", "ml-worker"]
```

#### Pod Affinity

Colocate pods together for low latency:

| Parameter | Description | Type |
|-----------|-------------|------|
| `affinity.podAffinity.preferComponents` | Soft constraint - prefer same node as components | `[]` |
| `affinity.podAffinity.requireComponents` | Hard constraint - require same node as components | `[]` |
| `affinity.podAffinity.custom` | Full Kubernetes podAffinity syntax | `{}` |

**Example - Colocate with cache:**
```yaml
components:
  cache:
    replicas: 2

  api:
    affinity:
      podAffinity:
        preferComponents: ["cache"]
```

#### Global Affinity

Apply affinity defaults to all components:

```yaml
global:
  affinity:
    podAntiAffinity:
      preferredSpreadBy: ["kubernetes.io/hostname"]

components:
  web:
    # inherits global affinity

  worker:
    # override global affinity
    affinity:
      podAntiAffinity:
        avoidComponents: ["web"]

  cache:
    # disable global affinity
    affinity: null
```

#### Advanced Custom Syntax

For complex scenarios not covered by shortcuts:

```yaml
components:
  web:
    affinity:
      nodeAffinity:
        custom:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In
                values: ["r5.xlarge", "r5.2xlarge"]
```

See [values-affinity.yaml](../../tests/app/values-affinity.yaml) for comprehensive examples.

### Persistence (PersistentVolumes & PersistentVolumeClaims)

The chart supports three complementary ways to use persistent storage:

1. **Per-component PVC (auto-created)** — the common case. Component gets its own PVC dynamically provisioned by a `StorageClass`.
2. **Chart-level shared PVC** — one PVC referenced by multiple components (typically `ReadWriteMany`).
3. **Chart-level static PV** — cluster-scoped `PersistentVolume` for pre-provisioned storage (NFS, hostPath, CSI handle).

Volumes are automatically mounted into main container, initContainers, and additionalContainers.

#### Per-component persistence (auto-created PVC)

```yaml
components:
  web:
    persistence:
      - name: cache             # PVC name: {release}-{component}-cache
        size: 5Gi
        accessModes: [ReadWriteOnce]
        storageClassName: gp3
        mountPath: /var/cache
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence[].name` | Volume name (also used to derive PVC name) | Required |
| `persistence[].mountPath` | Container mount path | Required |
| `persistence[].size` | Requested storage size | Required (unless `existingClaim`) |
| `persistence[].accessModes` | Access modes | `[ReadWriteOnce]` |
| `persistence[].storageClassName` | StorageClass to use | Cluster default |
| `persistence[].subPath` | Mount a subpath | `""` |
| `persistence[].readOnly` | Mount read-only | `false` |
| `persistence[].existingClaim` | Reference an existing PVC (skips creation) | `null` |
| `persistence[].volumeName` | Bind to a specific PV | `null` |
| `persistence[].labels` / `.annotations` | Extra metadata on the created PVC | `{}` |

#### Shared PVC between components

```yaml
persistentVolumeClaims:
  - name: shared-uploads
    size: 20Gi
    accessModes: [ReadWriteMany]
    storageClassName: efs-sc

components:
  web:
    persistence:
      - name: uploads
        existingClaim: shared-uploads
        mountPath: /var/www/uploads
  worker:
    persistence:
      - name: uploads
        existingClaim: shared-uploads
        mountPath: /var/www/uploads
```

#### Static PersistentVolume (NFS / hostPath / CSI)

```yaml
persistentVolumes:
  - name: shared-nfs
    capacity: 100Gi
    accessModes: [ReadWriteMany]
    storageClassName: ""
    reclaimPolicy: Retain
    nfs:
      server: nfs.example.com
      path: /exports/shared

persistentVolumeClaims:
  - name: nfs-claim
    size: 100Gi
    accessModes: [ReadWriteMany]
    storageClassName: ""
    volumeName: shared-nfs        # bind explicitly to the PV above
```

Supported source shortcuts on `persistentVolumes[]`: `nfs`, `hostPath`, `csi`, `local`. For any other source type use `source:` and provide raw K8s YAML.

#### DigitalOcean Kubernetes (DOKS)

DO Block Storage (`do-block-storage`) is **ReadWriteOnce only** — a volume is attached to exactly one node at a time. Plan accordingly:

**Per-component private storage** (works out of the box):

```yaml
components:
  web:
    replicas: 1               # RWO: cannot scale replicas on the same PVC
    strategy:
      type: Recreate          # avoid attach conflicts on rolling updates
    persistence:
      - name: data
        size: 10Gi
        accessModes: [ReadWriteOnce]
        storageClassName: do-block-storage
        mountPath: /data
```

Notes:
- Rolling updates with `ReadWriteOnce` can deadlock on volume attach — use `strategy.type: Recreate` unless the old pod fully terminates first.
- Volumes are region-locked; combine with node affinity if you have multi-region node pools.

**Shared storage across replicas / components (RWX)** — DO block storage does NOT support this. Options:

1. **DO Spaces (S3-compatible)** — application-level, no PVC. Best fit for uploads, media, backups.
2. **Self-hosted NFS server** — expose it via `persistentVolumes:` with `nfs:`.
3. **Cluster storage add-ons** — install [Longhorn](https://longhorn.io/) or Rook-Ceph on top of DO block storage to get RWX.

**NFS example on DO** (assumes an NFS server running in the cluster or a Droplet):

```yaml
persistentVolumes:
  - name: uploads-nfs
    capacity: 50Gi
    accessModes: [ReadWriteMany]
    storageClassName: ""
    reclaimPolicy: Retain
    nfs:
      server: 10.10.0.5       # private VPC IP of the NFS server
      path: /exports/uploads

persistentVolumeClaims:
  - name: uploads
    size: 50Gi
    accessModes: [ReadWriteMany]
    storageClassName: ""
    volumeName: uploads-nfs

components:
  web:
    replicas: 3
    persistence:
      - name: uploads
        existingClaim: uploads
        mountPath: /var/www/uploads
  worker:
    replicas: 5
    persistence:
      - name: uploads
        existingClaim: uploads
        mountPath: /var/www/uploads
```

See [values-persistence.yaml](../../tests/app/values-persistence.yaml) for a full example covering all three patterns.

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

### Security Path Filter

Block access to sensitive paths by creating a standalone blocking Ingress resource. Blocked paths are routed to a non-existent backend service, causing NGINX to return 404.

The security path filter supports global defaults with per-component overrides (same pattern as affinity):

```yaml
global:
  securityPathFilter:
    enabled: true
    blockedPaths:
      - "/.git"
      - "/.env"

components:
  web:
    ingress:
      enabled: true
      # inherits global.securityPathFilter
  api:
    ingress:
      enabled: true
      securityPathFilter:
        enabled: true
        blockedPaths: ["/.git", "/.env", "/vendor"]  # override global
  admin:
    ingress:
      enabled: true
      securityPathFilter:
        enabled: false  # disable for this component
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

### Pod & Container Security Context

Set pod-level (`fsGroup`, `runAsUser`, `runAsGroup`, `runAsNonRoot`, …) and container-level (`capabilities`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`, …) security context. Both support global defaults with component-level overrides (same pattern as affinity / securityPathFilter).

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.podSecurityContext` | Default pod-level securityContext for every component | `{}` |
| `global.securityContext` | Default container-level securityContext for every container | `{}` |
| `components.<name>.podSecurityContext` | Overrides `global.podSecurityContext`. Set to `null` to disable the inherited default | inherits global |
| `components.<name>.securityContext` | Overrides `global.securityContext` on the main container | inherits global |
| `initContainers[].securityContext` | Overrides `global.securityContext` on an init container | inherits global |
| `additionalContainers[].securityContext` | Overrides `global.securityContext` on a sidecar container | inherits global |
| `jobs[].securityContext` / `jobs[].podSecurityContext` | Same semantics for Jobs | inherits global |
| `cronJobs[].securityContext` / `cronJobs[].podSecurityContext` | Same semantics for CronJobs | inherits global |

**Example — Pod Security Standard "restricted" baseline for the whole release:**

```yaml
global:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop: [ALL]

components:
  web:
    # inherits global — no override needed
```

**Example — fix RWO PVC ownership with `fsGroup`:**

On block-storage CSI drivers (DO, AWS EBS, GCP PD) a freshly-provisioned PVC is mounted as `root:root` (mode 755). Non-root containers can't write. Setting `fsGroup` tells the kubelet to recursively `chown` the volume to that GID at mount time — the standard fix, avoids initContainer chown hacks.

```yaml
components:
  hermes:
    image: nousresearch/hermes-agent
    podSecurityContext:
      fsGroup: 10000               # matches the image's runtime user GID
    persistence:
      - name: data
        size: 10Gi
        accessModes: [ReadWriteOnce]
        storageClassName: do-block-storage
        mountPath: /opt/data
```

**Example — an init container needs root to run `chown`, main container drops privileges:**

```yaml
components:
  legacy:
    image: legacy/app:1.0
    podSecurityContext:
      runAsNonRoot: true
      runAsUser: 1000
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ALL]
    initContainers:
      - name: chown-legacy-data
        image: busybox:1.36
        command: "chown -R 1000:1000 /var/data"
        # Override the inherited security context: this init needs to run as root.
        securityContext:
          runAsUser: 0
          runAsGroup: 0
          runAsNonRoot: false
```

**Disabling an inherited default** — set the field to `null` explicitly:

```yaml
global:
  securityContext:
    readOnlyRootFilesystem: true

components:
  needs-writable-rootfs:
    securityContext: null          # opts out entirely
```

### Container Command & Args

The chart supports three ways to control what a container runs:

| Form | K8s field mapping | Effect on image ENTRYPOINT |
|------|-------------------|----------------------------|
| `command: "cmd with args"` (string) | `command: ['sh', '-c', "cmd with args"]` | Replaces ENTRYPOINT with a shell |
| `command: [foo, bar]` (list) | `command: [foo, bar]` | Replaces ENTRYPOINT (no shell) |
| `args: [foo, bar]` (list) | `args: [foo, bar]` | Keeps ENTRYPOINT, overrides CMD |

**When to use which:**

- **String `command:`** — legacy default. Convenient for `php artisan queue:work`-style commands where you want shell features (env expansion, `&&`, redirection). Wrapped in `sh -c "..."` so `ENTRYPOINT` is replaced.
- **List `command:`** — when you want the exec form (no shell) but still fully replace `ENTRYPOINT`. Rarely needed.
- **`args:`** — the right choice for images that already have a proper `ENTRYPOINT` you want to keep: s6-overlay, tini, dumb-init, or any wrapper script that sets up the environment before starting the app. Overrides only `CMD`, so the image's init sequence still runs.

**Example — image with s6-overlay ENTRYPOINT that must run before the app command:**

```yaml
components:
  hermes:
    image: nousresearch/hermes-agent
    # Wrong: `command: "gateway run"` would replace /init (s6-overlay), skipping
    # ownership fix hooks and losing the supervision tree.
    # Right: keep /init, only override CMD.
    args: [gateway, run]
```

Fields available on every container spec (main / init / additional / jobs / cronJobs): `command` (string or list), `args` (list), `securityContext`.

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
- [Affinity examples](../../tests/app/values-affinity.yaml)

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

# Affinity examples
make template-app-affinity

# Output will be in .build/app/
```

## Version History

- **1.6.0** - Added optional deployment strategy configuration per component
- **1.2.0** - Replaced server-snippet security path filter with standalone blocking Ingress, added global securityPathFilter support
- **1.1.0** - Added comprehensive affinity support (node affinity, pod affinity, pod anti-affinity)
- **1.0.3** - Maintenance release
- **1.0.0** - Initial release