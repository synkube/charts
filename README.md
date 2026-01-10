# Synkube Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/synkube)](https://artifacthub.io/packages/search?repo=synkube)
[![Helm Version](https://img.shields.io/badge/Helm-v3.x-blue)](https://helm.sh)

Reusable Helm charts for Kubernetes platform and application deployments.

## Charts

| Chart | Description | Scope |
|-------|-------------|-------|
| **app-starter** | Streamlined chart for deploying applications (Deployments, StatefulSets, CronJobs, Services, Ingress, etc.) | Namespace |
| **app-extensions** | Additional namespace-scoped resources (Secrets, ConfigMaps, RBAC, NetworkPolicies) | Namespace |
| **platform-extensions** | Cluster-scoped resources (ClusterRoles, ClusterSecretStores, Certificates) | Cluster |
| **common** | Library chart with shared helper functions | Library |

## Installation

### Option 1: OCI Registry (Recommended)

```bash
# Install directly from OCI
helm install myapp oci://ghcr.io/synkube/charts/app-starter --version 1.1.0 -f values.yaml

# Or pull first, then install
helm pull oci://ghcr.io/synkube/charts/app-starter --version 1.1.0
helm install myapp ./app-starter-1.1.0.tgz -f values.yaml
```

### Option 2: Helm Repository (GitHub Pages)

```bash
# Add the Helm repository
helm repo add synkube https://synkube.github.io/charts
helm repo update

# Search available charts
helm search repo synkube

# Install a chart
helm install myapp synkube/app-starter -f values.yaml
```

## Quick Start Examples

### Deploy a Web Application

```yaml
# values.yaml
image:
  repository: nginx
  tag: "1.25"

container:
  ports:
    - name: http
      containerPort: 80

service:
  ports:
    - port: 80
      targetPort: 80
      name: http

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: myapp.example.com
      paths: ["/"]
```

```bash
helm install myapp synkube/app-starter -f values.yaml
```
