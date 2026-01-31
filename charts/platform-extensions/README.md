# platform-extensions

Cluster-scoped Kubernetes resources for platform teams.

## What It Does

Manage cluster-wide infrastructure without writing YAML:

- **ClusterSecretStores** - Cluster-wide secret providers
- **ClusterRoles & ClusterRoleBindings** - Cluster RBAC
- **StorageClasses** - Storage provisioner configs
- **VolumeSnapshotClasses** - Backup configurations
- **VolumeSnapshots** - One-off point-in-time backups
- **ScheduledVolumeSnapshots** - Automated backup schedules
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

## Volume Snapshots

### One-off Snapshots

Create manual point-in-time backups:

```yaml
volumeSnapshots:
  my-db-backup-jan-2025:
    namespace: data
    pvcName: postgres-data
    volumeSnapshotClassName: standard
    labels:
      backup-type: manual
```

### Scheduled Snapshots

Automated backup schedules (requires `scheduled-volume-snapshotter` operator):

```bash
# Install the operator first
helm repo add scheduled-volume-snapshotter https://ryaneorth.github.io/k8s-scheduled-volume-snapshotter
helm install scheduled-volume-snapshotter scheduled-volume-snapshotter/scheduled-volume-snapshotter -n platform
```

```yaml
scheduledVolumeSnapshots:
  postgres-daily:
    namespace: data
    pvcName: postgres-data
    snapshotClassName: standard
    snapshotFrequency: 24h   # 30m, 5h, 4d, 1w
    snapshotRetention: 7d    # how long to keep
    snapshotLabels:
      database: postgres
```

## Requirements

| Dependency | Required For |
|------------|--------------|
| external-secrets-operator | ClusterSecretStores |
| cert-manager | ClusterIssuers, Certificates |
| Gateway API CRDs | GatewayClasses, Gateways |
| snapshot-controller | VolumeSnapshotClasses, VolumeSnapshots |
| scheduled-volume-snapshotter | ScheduledVolumeSnapshots |

