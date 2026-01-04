# Synkube Charts

Helm charts for Kubernetes platform and application extensions.

## Charts

### app-extensions
Namespace-scoped resources for application teams. Safe resources that cannot escalate privileges.

### platform-extensions
Cluster-scoped resources for platform teams. Requires cluster-admin permissions.

## Usage

```bash
# Add this repository
helm repo add synkube ./

# Install app extensions (namespace-scoped)
helm install myapp-ext synkube/app-extensions -f values.yaml

# Install platform extensions (cluster-admin required)
helm install platform synkube/platform-extensions -f platform-values.yaml
```
