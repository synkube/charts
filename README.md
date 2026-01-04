# Synkube Helm Charts

Helm chart repository for Synkube platform and application extensions.

## Usage

```bash
# Add this Helm repository
helm repo add synkube https://synkube.github.io/charts
helm repo update

# Search available charts
helm search repo synkube

# Install a chart
helm install my-release synkube/app-extensions -f values.yaml
```

## Available Charts

| Chart | Description |
|-------|-------------|
| `app-extensions` | Namespace-scoped resources for application teams |
| `platform-extensions` | Cluster-scoped resources for platform teams |
| `common` | Library chart with shared utilities |

## OCI Registry

Charts are also available via OCI:

```bash
helm pull oci://ghcr.io/synkube/charts/app-extensions --version 1.0.0
```

## Source

Source code: [github.com/synkube/charts](https://github.com/synkube/charts)
