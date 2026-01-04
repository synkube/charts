# App Extensions Test Values

This directory contains test value files for the `app-extensions` chart, demonstrating various configurations and use cases.

## Test Files

### `01-simple-secrets.yaml`
**Purpose**: Basic secrets and ConfigMaps with templating
**Features**:
- Regular Kubernetes Secrets with templating support
- ConfigMaps with Helm templating for dynamic configuration
- Multiple data formats (YAML, JSON, text)

### `02-external-secrets.yaml`
**Purpose**: External Secrets integration with multiple providers
**Features**:
- ExternalSecret resources syncing from different sources
- Namespace-scoped SecretStore configuration
- Integration with ClusterSecretStore (created by platform team)
- Service Account for secret access

### `03-rbac-networking.yaml`
**Purpose**: RBAC and NetworkPolicies for app-level security
**Features**:
- ServiceAccounts for different application components
- Namespace-scoped Roles and RoleBindings
- Network policies for micro-segmentation
- Multi-tier application security

### `04-storage-sealed-secrets.yaml`
**Purpose**: Storage and encrypted secrets management
**Features**:
- PersistentVolumeClaims with different storage classes
- SealedSecrets for encrypted secret management
- Storage configuration management
- RBAC for storage operations

### `05-full-featured.yaml`
**Purpose**: Comprehensive integration of all features
**Features**:
- Complete integration of secrets, RBAC, networking, and storage
- Multiple secret sources and types
- Complex RBAC setup with multiple service accounts
- Network segmentation and storage management
- Production-ready configuration example

## Running Tests

Execute all tests:
```bash
./test-render.sh
```

Test a specific configuration:
```bash
helm template myapp app-extensions -f test-values/01-simple-secrets.yaml
```

## Usage Patterns

### For Application Teams
These test files demonstrate how application teams can use `app-extensions` to:
- Manage application secrets and configuration
- Set up necessary RBAC for their services
- Configure network policies for their applications
- Request storage resources

### Security Boundaries
All resources in these tests are **namespace-scoped** and safe for application teams to deploy:
- ✅ No cluster-admin permissions required
- ✅ Cannot escalate privileges beyond namespace
- ✅ Cannot affect other namespaces or cluster resources

## Integration with Platform

Many examples reference platform resources (like ClusterSecretStore) that must be created by the platform team using `platform-extensions` chart first.

## Templating Support

All test files demonstrate Helm templating capabilities:
- Dynamic resource naming based on release
- Environment-specific configuration
- Cross-resource references within the same chart
