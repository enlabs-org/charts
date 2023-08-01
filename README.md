# Helm Charts

![Helm Charts](https://github.com/enlabs-org/charts/actions/workflows/helm-dry-run.yml/badge.svg?branch=main)

### Preview App Chart
```yaml
---
# Deployment
useDefaultDeployment: true
image: ''
replicas: 1
containerPort: 80
livenessProbePath: '/'
restartAfterRedeploy: false
envFromSecret: null
sideContainers: []

# Service
useDefaultService: true

# Ingress
useDefaultIngress: true
host: ''
wwwRedirect: false
tls: true
issueCertificate: true
clusterIssuer: 'letsencrypt'
tlsSecretName: ''

```