# platform-extensions

Cluster-scoped Kubernetes resources for platform teams.

## What It Does

Manage cluster-wide infrastructure without writing YAML:

- **ClusterSecretStores** - Cluster-wide secret providers
- **ClusterRoles & ClusterRoleBindings** - Cluster RBAC
- **StorageClasses** - Storage provisioner configs
- **VolumeSnapshotClasses** - Backup configurations
- **PriorityClasses** - Workload scheduling priorities
- **ResourceQuotas** - Namespace resource limits
- **LimitRanges** - Default resource constraints
- **NetworkPolicies** - Platform-wide network rules
- **IngressClasses** - Ingress controller definitions
- **GatewayClasses & Gateways** - Gateway API resources
- **ClusterIssuers** - cert-manager CAs
- **Certificates** - TLS certificates

## Install

```bash
helm repo add synkube https://synkube.github.io/charts
helm install platform synkube/platform-extensions -f values.yaml
```

## Quick Example

```yaml
clusterSecretStores:
  infisical:
    provider:
      infisical:
        auth:
          universalAuthCredentials:
            clientId:
              secretRef:
                name: infisical-auth
                key: clientId
            clientSecret:
              secretRef:
                name: infisical-auth
                key: clientSecret
        hostAPI: "https://app.infisical.com/api"

storageClasses:
  fast-ssd:
    provisioner: pd.csi.storage.gke.io
    parameters:
      type: pd-ssd
    allowVolumeExpansion: true

priorityClasses:
  critical:
    value: 1000000
    description: "Critical workloads"

clusterIssuers:
  letsencrypt-prod:
    acme:
      server: https://acme-v02.api.letsencrypt.org/directory
      email: admin@example.com
      privateKeySecretRef:
        name: letsencrypt-prod-key
      solvers:
        - http01:
            ingress:
              class: nginx
```

## Requirements

| Dependency | Required For |
|------------|--------------|
| external-secrets-operator | ClusterSecretStores |
| cert-manager | ClusterIssuers, Certificates |
| Gateway API CRDs | GatewayClasses, Gateways |
| snapshot-controller | VolumeSnapshotClasses |

