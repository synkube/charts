# Generic-App Test Values

This directory contains test value files for validating the `app-starter` Helm chart rendering.

## Running Tests

```bash
# From the app-starter directory:
./test-render.sh

# Or from anywhere:
bash /path/to/app-starter/test-render.sh
```

The test script automatically discovers all `.yaml` and `.yml` files in this directory and tests them.

## Test Scenarios

### 01-simple-web-app.yaml
**Purpose:** Minimal web application with Deployment
**Tests:**
- Simple Deployment with 2 replicas
- Basic Service configuration
- Ingress with TLS
- Resource limits and probes
- Minimal configuration (starter template)

### 02-statefulset-app.yaml
**Purpose:** StatefulSet with persistent storage
**Tests:**
- StatefulSet instead of Deployment
- Init containers
- Persistent volume claims (volumeClaimTemplates)
- Headless service
- Pod Disruption Budget

### 03-grpc-multiport.yaml
**Purpose:** Multi-port service with metrics
**Tests:**
- Multiple container ports (http, grpc, metrics)
- Multiple service ports
- ServiceMonitor for Prometheus
- Horizontal Pod Autoscaler
- Custom service labels

### 04-with-migrations.yaml
**Purpose:** Application with database migrations
**Tests:**
- Migration Job (with ArgoCD PreSync hook)
- ConfigMap for migration scripts
- Secrets (base64 encoded)
- ConfigMap file mounting
- Environment variables from secrets

### 05-with-cronjobs.yaml
**Purpose:** Application with scheduled jobs
**Tests:**
- Multiple CronJob definitions
- Different schedules and policies
- Per-job environment variables
- Per-job resource limits

### 06-full-featured.yaml
**Purpose:** Full-featured production-ready app
**Tests:**
- ServiceAccount with annotations
- HPA with custom metrics and behavior
- VPA (Vertical Pod Autoscaler)
- Pod Disruption Budget
- ServiceMonitor
- Multiple probes (liveness, readiness, startup)
- Security contexts
- Affinity and tolerations
- Reloader integration
- Image pull secrets

### 07-gateway-api.yaml
**Purpose:** Gateway API (next-generation Ingress)
**Tests:**
- HTTPRoute instead of Ingress
- Multiple hostnames
- Path-based routing
- Request header modification filters
- Parent Gateway references
- CRD capability check

### 08-gateway-advanced.yaml
**Purpose:** Advanced Gateway API features
**Tests:**
- Gateway API with advanced routing
- Multiple rules and matches
- Backend traffic splitting (canary deployments)
- Request/response filters

### 09-with-sidecars.yaml
**Purpose:** Multi-container pod with sidecars
**Tests:**
- additionalContainers for sidecars
- Shared volumes between containers
- Multiple containers with different resource limits
- Log shipping sidecar pattern
- Metrics exporter sidecar

### 10-env-merging.yaml
**Purpose:** Environment variable merging
**Tests:**
- container.env (array format)
- container.envMap (map format)
- container.extraEnv (override format)
- Env var precedence and merging
- envFromSecrets and envFromConfigmaps
- Secrets as environment variables

### 11-deployment-with-pvc.yaml
**Purpose:** Deployment with PersistentVolumeClaim
**Tests:**
- PVC pattern for Deployment (vs StatefulSet's volumeClaimTemplates)
- Persistent storage configuration
- Storage class specification
- Volume mounting

### 12-advanced-deployment-config.yaml
**Purpose:** Advanced Deployment features
**Tests:**
- nameOverride customization
- Deployment annotations
- Custom deployment strategy (RollingUpdate settings)
- Command and args override
- Lifecycle hooks (postStart, preStop)
- Custom container name
- Pod annotations and labels
- terminationGracePeriodSeconds
- revisionHistoryLimit
- All three probe types (liveness, readiness, startup)

### 13-secret-and-config-mounts.yaml
**Purpose:** Secrets and ConfigMaps as file mounts
**Tests:**
- secretMounts (mounting secrets as files)
- configMaps file mounting (multiple files)
- Custom volumes (emptyDir with size limits)
- container.volumes and volumeMounts
- envFromSecrets for env vars
- Multiple mount paths

### 14-statefulset-advanced.yaml
**Purpose:** Advanced StatefulSet configuration
**Tests:**
- StatefulSet annotations
- podManagementPolicy: Parallel
- updateStrategy with partition
- fullnameOverride
- Init containers (multiple)
- Container and pod security contexts
- Headless service
- volumeClaimTemplates (StatefulSet persistence)
- Node selector
- Tolerations
- Pod anti-affinity
- High replica count (5 replicas)

### 15-service-types-and-ingress.yaml
**Purpose:** Different service types and ingress configurations
**Tests:**
- Service type: LoadBalancer
- Service labels
- ingress.className
- Multiple ingress hosts
- Multiple TLS certificates
- Ingress annotations

### 16-migrations-env-override.yaml
**Purpose:** Migration job environment variable merging
**Tests:**
- container.env as baseline
- migrations.env overrides
- Env var precedence for migration jobs
- Deduplication of duplicate env vars
- Secret references in migration jobs

### 17-statefulset-shared-storage.yaml
**Purpose:** StatefulSet with shared PVC (alternative to volumeClaimTemplates)
**Tests:**
- persistence.sharedStorage: true
- Regular PVC (not volumeClaimTemplates)
- ReadWriteMany access mode
- All StatefulSet pods mount same volume
- Use case: shared uploads, logs, configuration

### 18-templating-features.yaml
**Purpose:** Helm templating (tpl) features across all resources
**Tests:**
- Secrets with templating (dynamic connection strings)
- Environment variables with templating (env, envMap)
- valueFrom references preserved (NOT templated)
- ConfigMaps with templating
- Migration commands with templating
- Nested template functions (include)
- Dynamic values based on Release, Chart, and Values context
- Demonstrates backtick quoting for template functions in strings

## Adding New Tests

To add a new test scenario:

1. Create a new `.yaml` file in this directory (e.g., `07-my-test.yaml`)
2. Add your custom values
3. Run `./test-render.sh` - it will automatically pick up the new file

## What Gets Validated

### Level 1: Helm Template Rendering ✅ (Always)
- ✓ Helm template syntax is correct
- ✓ Go template logic works properly
- ✓ YAML is syntactically valid
- ✓ Kubernetes resources are generated
- ✓ Resource types and counts

### Level 2: Kubernetes Schema Validation ✅ (with --validate=strict)
- ✓ Server-side validation (if cluster available) - most accurate
- ✓ Client-side validation (fallback) - works in CI/CD without cluster
- ✓ Catches type errors, constraint violations, and invalid field names
- ✓ RFC 1123 name validation
- ⚠️ Skipped only if kubectl not found

### What Is NOT Validated
- ❌ Runtime behavior (requires actual deployment)
- ❌ Resource references (e.g., if a secret actually exists)
- ❌ RBAC permissions
- ❌ Network policies
- ❌ Storage class availability

## Test Output

Each test shows:
- ✓ Helm template: SUCCESS/FAILED
- Resource count and types generated
- Kubernetes validation status (if applicable)

Failed tests show:
- ✗ Error messages from Helm
- Last 15 lines of output for debugging

## Expected Results

| Test File | Resources Generated |
|-----------|---------------------|
| 01-simple-web-app | Deployment, Service, Ingress |
| 02-statefulset-app | StatefulSet, Service, PodDisruptionBudget |
| 03-grpc-multiport | Deployment, Service, Ingress, ServiceMonitor, HPA |
| 04-with-migrations | Deployment, Service, Job, ConfigMap (x2), Secret |
| 05-with-cronjobs | Deployment, Service, CronJob (x2) |
| 06-full-featured | Deployment, Service, Ingress, ServiceAccount, ServiceMonitor, HPA, VPA, PodDisruptionBudget |
| 07-gateway-api | Deployment, Service (HTTPRoute if CRDs installed) |
| 08-gateway-advanced | Deployment, Service (HTTPRoute if CRDs installed) |
| 09-with-sidecars | Deployment, Service |
| 10-env-merging | Deployment, Service, Secret |
| 11-deployment-with-pvc | Deployment, Service, PersistentVolumeClaim |
| 12-advanced-deployment-config | Deployment, Service |
| 13-secret-and-config-mounts | Deployment, Service, ConfigMap, Secret |
| 14-statefulset-advanced | StatefulSet, Service, PodDisruptionBudget |
| 15-service-types-and-ingress | Deployment, Service, Ingress |
| 16-migrations-env-override | Deployment, Service, Job, ConfigMap |
| 17-statefulset-shared-storage | StatefulSet, Service, PersistentVolumeClaim |
| 18-templating-features | Deployment, Service, Ingress, Secret, ConfigMap (x2), Job |

## Cleanup

Test outputs are automatically cleaned up after each run. Temporary files are stored in `.test-output/` (gitignored).

