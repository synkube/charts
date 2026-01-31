# Platform Extensions Test Values

This directory contains test value files for the `platform-extensions` chart, demonstrating cluster-wide infrastructure configurations.

⚠️ **NOTE**: Resources in this chart are cluster-scoped and require **cluster-admin** permissions when enabled. If all values are empty (default), no resources are created and no special permissions are needed.

## Test Files

### `01-cluster-storage.yaml`
**Purpose**: Cluster-wide storage configuration
**Features**:
- StorageClasses for different performance tiers (SSD, balanced, NFS)
- VolumeSnapshotClasses for backup/restore operations
- PriorityClasses for workload scheduling priorities
- Multi-zone and regional storage configurations

### `02-cluster-rbac.yaml`
**Purpose**: Cluster-wide RBAC management
**Features**:
- ClusterRoles with comprehensive permission sets
- ClusterRoleBindings for different user groups
- RBAC aggregation rules for modular permissions
- Service account bindings for system components

### `03-secrets-networking.yaml`
**Purpose**: Cluster secret stores and advanced networking
**Features**:
- ClusterSecretStores for organization-wide secret management
- IngressClasses for different ingress controllers
- GatewayClasses and Gateways for Gateway API
- Platform-wide NetworkPolicies for security

### `04-governance-certificates.yaml`
**Purpose**: Resource governance and certificate management
**Features**:
- ResourceQuotas for different environments
- LimitRanges for resource constraints
- Platform TLS certificates (wildcards, internal CA)
- Multi-environment resource management

### `05-simple-certificates.yaml`
**Purpose**: Simple certificate configuration
**Features**:
- Basic ClusterIssuer setup
- Simple certificate generation

### `06-webhooks-leases.yaml`
**Purpose**: Admission webhooks and leader election
**Features**:
- ValidatingWebhookConfigurations for policy enforcement
- MutatingWebhookConfigurations for sidecar injection
- Leases for controller leader election
- Multi-zone scheduler locks
- Match conditions and namespace selectors

## Running Tests

Execute all tests:
```bash
./test-render.sh
```

Test a specific configuration:
```bash
helm template platform platform-extensions -f test-values/01-cluster-storage.yaml
```

## Security Considerations

### Required Permissions
This chart creates cluster-scoped resources that require:
- **cluster-admin** role or equivalent permissions
- Access to create/modify cluster-wide resources
- Permission to manage cross-namespace resources

### Dangerous Resources
The chart manages resources that can affect the entire cluster:
- ❌ ClusterRoles/ClusterRoleBindings (privilege escalation risk)
- ❌ StorageClasses (cluster-wide storage impact)
- ❌ ClusterSecretStores (cross-namespace secret access)
- ❌ ResourceQuotas/LimitRanges (can bypass application limits)

## Usage Patterns

### For Platform Teams
These test files show how platform teams use `platform-extensions` to:
- Bootstrap cluster infrastructure
- Set organization-wide policies and limits
- Manage cross-cutting concerns (storage, networking, security)
- Provide services that application teams consume

### Deployment Strategy
1. **Platform Team**: Deploys `platform-extensions` with cluster-admin
2. **Application Teams**: Reference platform resources in `app-extensions`
3. **Dependencies**: Applications depend on platform resources being available

## Integration Points

### With app-extensions
Platform resources are referenced by app-extensions:
- ClusterSecretStores → referenced in ExternalSecrets
- StorageClasses → used in PersistentVolumeClaims
- IngressClasses → used in Ingress resources
- NetworkPolicies → work with app-level policies

### Environment Management
Test files demonstrate multi-environment patterns:
- Production: Strict quotas and security
- Staging: Moderate resource limits
- Development: Relaxed constraints
- Cross-environment certificate management

## Validation Notes

The test script includes special handling for cluster-admin validation:
- Checks for cluster-admin permissions before server-side validation
- Warns about cluster-scoped resource requirements
- Provides appropriate fallbacks for limited permission environments
