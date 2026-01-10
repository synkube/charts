# App-Starter Helm Chart

A streamlined, extensible Helm chart for deploying applications on Kubernetes. This chart provides a flexible foundation for deploying stateless and stateful applications with production-ready configurations.

## Overview

The `app-starter` chart is designed to eliminate boilerplate while maintaining flexibility. It supports a wide range of deployment patterns from simple web applications to complex stateful services with sidecars, migrations, and scheduled jobs.

> **Note**: This chart depends on the `common` library chart for shared helpers like `common.hasApi`.

### Philosophy

- **Sensible Defaults**: Works out of the box with minimal configuration
- **Progressive Enhancement**: Start simple, add complexity as needed
- **Production-Ready**: Includes observability, scaling, and reliability features
- **Well-Documented**: Extensive inline comments and examples

## Supported Kubernetes Resources

### Core Workloads
- **Deployment** - Stateless applications (default)
- **StatefulSet** - Stateful applications with persistent identity
- **Job** - One-time or migration tasks
- **CronJob** - Scheduled recurring tasks

### Networking
- **Service** - ClusterIP, NodePort, LoadBalancer, Headless
- **Ingress** - Traditional ingress routing (nginx, traefik, etc.)
- **HTTPRoute** - Gateway API (next-generation ingress)

### Storage
- **PersistentVolumeClaim** - Persistent storage
  - Shared PVC for Deployments
  - Per-pod PVC via volumeClaimTemplates (StatefulSet)
  - Shared storage option for StatefulSet
- **ConfigMap** - Configuration files and data
- **Secret** - Sensitive data

### Scaling & Availability
- **HorizontalPodAutoscaler (HPA)** - CPU/Memory/Custom metrics
- **VerticalPodAutoscaler (VPA)** - Resource recommendation
- **PodDisruptionBudget (PDB)** - High availability during disruptions

### Observability
- **ServiceMonitor** - Prometheus metrics scraping
- Pod annotations for monitoring integration
- Configurable probes (liveness, readiness, startup)

### Security & Identity
- **ServiceAccount** - Pod identity with RBAC
- Security contexts (pod and container level)
- Image pull secrets

## Quick Start

### Minimal Deployment

```yaml
# values.yaml
image:
  repository: nginx
  tag: "1.25"

container:
  ports:
    - name: http
      containerPort: 80
```

```bash
helm install my-app ./app-starter -f values.yaml
```

### Simple Web Application

```yaml
replicaCount: 3

image:
  repository: myorg/myapp
  tag: "v1.2.3"

container:
  ports:
    - name: http
      containerPort: 8080

  env:
    - name: NODE_ENV
      value: "production"

  livenessProbe:
    httpGet:
      path: /health
      port: http

  readinessProbe:
    httpGet:
      path: /ready
      port: http

service:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8080
      name: http

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: myapp.example.com
      pathType: Prefix
      paths:
        - /
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Configuration Overview

### Image Configuration

```yaml
image:
  repository: nginx        # Container image repository
  tag: latest             # Image tag (defaults to Chart.appVersion)
  pullPolicy: IfNotPresent

imagePullSecrets:         # For private registries
  - name: registry-credentials
```

### Container Configuration

All container-level settings are under the `container` key:

```yaml
container:
  name: "main"           # Container name (defaults to chart name)

  # Execution
  command: []            # Override ENTRYPOINT
  args: []              # Override CMD

  # Ports
  ports:
    - name: http
      containerPort: 8080
      protocol: TCP

  # Environment Variables (3 formats supported)
  env: []               # Array format (Kubernetes native)
  envMap: {}            # Map format (more readable)
  extraEnv: []          # Override/addition format

  # Load all keys from ConfigMap/Secret as env vars
  envFrom: []
  envFromSecretName: ""
  envFromConfigmaps: []

  # Probes
  livenessProbe: {}
  readinessProbe: {}
  startupProbe: {}

  # Resources
  resources: {}

  # Security
  securityContext: {}

  # Lifecycle hooks
  lifecycle: {}

  # Volumes
  volumeMounts: []
  volumes: []
```

### Environment Variables - Multiple Formats

The chart supports three environment variable formats that are merged together:

```yaml
container:
  # Format 1: Array (Kubernetes native)
  env:
    - name: DATABASE_URL
      value: "postgresql://db:5432/mydb"
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-secret
          key: key

  # Format 2: Map (more readable, good for values file merging)
  envMap:
    LOG_LEVEL: "info"
    FEATURE_FLAG: "true"
    PORT: "8080"

  # Format 3: Extra env (highest precedence, for overrides)
  extraEnv:
    - name: LOG_LEVEL
      value: "debug"  # Overrides envMap value

  # Load all keys from external ConfigMap as env vars
  envFromConfigmaps:
    - shared-config
    - app-config

  # Load all keys from Secret as env vars
  envFromSecretName: my-secret
```

**Merge Order**: `env` → `envMap` → `extraEnv` (last wins for duplicates)

### Workload Types

#### Deployment (Default)

```yaml
deployment:
  enabled: true
  annotations: {}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

#### StatefulSet

```yaml
deployment:
  enabled: false

statefulSet:
  enabled: true
  annotations: {}
  serviceName: ""  # Defaults to chart fullname
  podManagementPolicy: "OrderedReady"  # or "Parallel"
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0

# Persistence options
persistence:
  enabled: true
  size: 10Gi
  storageClass: "fast-ssd"
  sharedStorage: false  # false = volumeClaimTemplates (per-pod)
                        # true = shared PVC (all pods share)
```

### Service Configuration

```yaml
service:
  enabled: true
  type: ClusterIP  # ClusterIP, NodePort, LoadBalancer
  headless: false  # true for StatefulSet headless service
  annotations: {}
  labels: {}

  ports:
    - port: 80           # Service port (cluster-facing)
      targetPort: 8080   # Container port (must match container.ports)
      name: http

# Multiple ports example
service:
  ports:
    - port: 80
      targetPort: 8080
      name: http
    - port: 9090
      targetPort: 9090
      name: grpc
    - port: 9091
      targetPort: 9091
      name: metrics
```

### Ingress & Gateway API

#### Traditional Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  servicePortName: http  # Must match service.ports[].name

  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"

  hosts:
    - host: app.example.com
      pathType: Prefix
      paths:
        - /

  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

#### Gateway API (HTTPRoute)

```yaml
gateway:
  enabled: true
  annotations: {}
  servicePort: 80

  parentRefs:
    - name: my-gateway
      namespace: gateway-system

  hostnames:
    - app.example.com

  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api

      # Advanced features
      timeouts:
        request: 30s
        backendRequest: 25s

      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: X-Custom-Header
                value: "value"

      # Traffic splitting (canary deployments)
      backendRefs:
        - name: myapp-stable
          port: 80
          weight: 90
        - name: myapp-canary
          port: 80
          weight: 10
```

### Storage & Configuration

#### Persistent Storage

```yaml
persistence:
  enabled: true
  storageClass: "standard"
  size: 10Gi
  accessModes:
    - ReadWriteOnce
  volumeName: "data"
  mountPath: "/data"

  # StatefulSet only: shared storage vs per-pod
  sharedStorage: false  # false = volumeClaimTemplates (default)
                        # true = shared PVC
```

#### ConfigMaps

ConfigMaps can be mounted as files or just stored (useful for external tools):

```yaml
configMaps:
  # Mounted as file
  app-config.yaml:
    mountPath: /etc/app/config.yaml
    content: |-
      database:
        host: db.example.com
        port: 5432

  # Stored in ConfigMap but NOT mounted (no mountPath)
  # Useful for metadata or external tools
  metadata.json:
    content: |-
      {"version": "1.0", "environment": "production"}
```

#### Secrets

```yaml
secrets:
  API_KEY: "my-secret-key"
  DB_PASSWORD: "super-secret"

# Mount secrets as files instead of env vars
secretMounts:
  tls-cert:
    secretKey: tls.crt
    mountPath: /etc/certs/
    fileName: cert.pem
```

### Scaling & Availability

#### Horizontal Pod Autoscaler

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

  # Custom metrics (requires Prometheus Adapter)
  customMetrics:
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "1000"

  # Scaling behavior
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
```

#### Vertical Pod Autoscaler

```yaml
vpa:
  enabled: true
  updatePolicy:
    updateMode: "Auto"  # Off, Initial, Recreate, Auto

  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 2
          memory: 2Gi
```

#### Pod Disruption Budget

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1        # Keep at least 1 pod available
  # maxUnavailable: 1    # OR: Allow at most 1 unavailable (not both)
```

### Jobs & Scheduling

#### Database Migrations

```yaml
migrations:
  enabled: true
  backoffLimit: 6
  restartPolicy: OnFailure
  randomizeJobName: true  # For ArgoCD PreSync hooks

  commands:
    - "npm run db:migrate"
    - "npm run db:seed"

  env:
    - name: MIGRATION_MODE
      value: "up"
```

#### CronJobs

```yaml
cronjobs:
  enabled: true
  suspend: false
  concurrencyPolicy: Forbid  # Allow, Forbid, Replace
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1

  cronjob:
    - name: cleanup
      schedule: "0 2 * * *"  # 2 AM daily
      command: ["/bin/bash"]
      args: ["-c", "/app/cleanup.sh"]
      env:
        - name: CLEANUP_DAYS
          value: "7"
      resources:
        requests:
          cpu: 100m
          memory: 128Mi

    - name: report
      schedule: "0 9 * * 1"  # 9 AM every Monday
      command: ["/app/report.sh"]
```

### Observability

#### ServiceMonitor (Prometheus)

```yaml
serviceMonitor:
  enabled: true
  port: "metrics"        # Must match service.ports[].name
  path: "/metrics"
  interval: "30s"
  scrapeTimeout: "10s"
```

#### Probes

```yaml
container:
  livenessProbe:
    httpGet:
      path: /health
      port: http
    initialDelaySeconds: 30
    timeoutSeconds: 5
    periodSeconds: 10
    failureThreshold: 3

  readinessProbe:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 10
    periodSeconds: 5

  startupProbe:
    httpGet:
      path: /startup
      port: http
    initialDelaySeconds: 0
    failureThreshold: 30
    periodSeconds: 10
```

### Security

#### Service Account

```yaml
serviceAccount:
  create: true
  name: "my-service-account"
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-role
  automountServiceAccountToken: true
```

#### Security Contexts

```yaml
# Pod-level
podSecurityContext:
  fsGroup: 2000
  runAsNonRoot: true
  runAsUser: 1000

# Container-level
container:
  securityContext:
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
```

### Advanced Features

#### Multi-Container Pods (Sidecars)

```yaml
additionalContainers:
  - name: log-shipper
    image: fluentd:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log/app

  - name: metrics-exporter
    image: nginx-exporter:latest
    ports:
      - containerPort: 9113
        name: metrics
```

#### Init Containers

```yaml
initContainers:
  - name: wait-for-db
    image: busybox:latest
    command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']

  - name: copy-config
    image: busybox:latest
    command: ['cp', '/config-source/app.conf', '/config/app.conf']
    volumeMounts:
      - name: config-source
        mountPath: /config-source
      - name: config
        mountPath: /config
```

#### Scheduling

```yaml
nodeSelector:
  disktype: ssd
  environment: production

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "app"
    effect: "NoSchedule"

affinity:
  # Spread pods across nodes
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - app-starter
          topologyKey: kubernetes.io/hostname
```

#### Reloader Integration

Automatically restart pods when ConfigMaps or Secrets change:

```yaml
reloader:
  enabled: true
  secretOnly: false      # Watch secrets only
  configMapOnly: false   # Watch configmaps only
```

Requires [Reloader](https://github.com/stakater/Reloader) operator.

## Using as a Dependency

The `app-starter` chart can be extended by adding it as a dependency in your own chart. This is useful when you need to customize templates or bundle multiple services together.

### Basic Dependency

```yaml
# Chart.yaml
apiVersion: v2
name: my-application
version: 1.0.0

dependencies:
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
```

Then configure in your values:

```yaml
# values.yaml
app-starter:
  image:
    repository: myorg/myapp
    tag: v1.0.0
  container:
    ports:
      - name: http
        containerPort: 8080
```

### Multiple Workloads with Aliases

Deploy multiple services from a single umbrella chart using aliases. Each alias creates an independent instance of `app-starter`:

```yaml
# Chart.yaml
apiVersion: v2
name: my-platform
version: 1.0.0

dependencies:
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
    alias: api
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
    alias: worker
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
    alias: scheduler
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
    alias: frontend
```

Configure each workload independently:

```yaml
# values.yaml
api:
  image:
    repository: myorg/api
    tag: v1.0.0
  container:
    ports:
      - name: http
        containerPort: 8080
      - name: metrics
        containerPort: 9090
  service:
    ports:
      - port: 80
        targetPort: 8080
        name: http
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: api.example.com
        paths: ["/"]
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10

worker:
  image:
    repository: myorg/worker
    tag: v1.0.0
  container:
    envMap:
      QUEUE_NAME: jobs
      CONCURRENCY: "5"
  # No service/ingress - internal worker

scheduler:
  image:
    repository: myorg/scheduler
    tag: v1.0.0
  deployment:
    enabled: false
  cronjobs:
    enabled: true
    cronjob:
      - name: daily-report
        schedule: "0 9 * * *"
        command: ["/app/report.sh"]
      - name: cleanup
        schedule: "0 2 * * *"
        command: ["/app/cleanup.sh"]

frontend:
  image:
    repository: myorg/frontend
    tag: v1.0.0
  container:
    ports:
      - name: http
        containerPort: 3000
  service:
    ports:
      - port: 80
        targetPort: 3000
        name: http
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: app.example.com
        paths: ["/"]
```

### Conditional Dependencies

Enable/disable workloads conditionally:

```yaml
# Chart.yaml
dependencies:
  - name: app-starter
    alias: worker
    condition: worker.enabled
```

```yaml
# values.yaml
worker:
  enabled: true  # Set to false to disable
  image:
    repository: myorg/worker
```

## Common Use Cases

### 1. Simple Web Application

```yaml
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

### 2. Stateful Application with Database

```yaml
deployment:
  enabled: false

statefulSet:
  enabled: true

persistence:
  enabled: true
  size: 20Gi
  storageClass: "fast-ssd"

service:
  headless: true

container:
  env:
    - name: PGDATA
      value: /data/postgres
```

### 3. Microservice with Observability

```yaml
container:
  ports:
    - name: http
      containerPort: 8080
    - name: metrics
      containerPort: 9090

service:
  ports:
    - port: 80
      targetPort: 8080
      name: http
    - port: 9090
      targetPort: 9090
      name: metrics

serviceMonitor:
  enabled: true
  port: metrics

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### 4. Application with Migrations and Scheduled Jobs

```yaml
migrations:
  enabled: true
  commands:
    - "npm run db:migrate"

cronjobs:
  enabled: true
  cronjob:
    - name: cleanup
      schedule: "0 2 * * *"
      command: ["/app/cleanup.sh"]

    - name: backup
      schedule: "0 3 * * *"
      command: ["/app/backup.sh"]
```

### 5. Multi-Environment Configuration

```yaml
# values-dev.yaml
replicaCount: 1
resources:
  requests:
    cpu: 100m
    memory: 128Mi

container:
  envMap:
    ENVIRONMENT: "development"
    LOG_LEVEL: "debug"

# values-prod.yaml
replicaCount: 3
resources:
  requests:
    cpu: 500m
    memory: 512Mi

container:
  envMap:
    ENVIRONMENT: "production"
    LOG_LEVEL: "info"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

## Testing

The chart includes comprehensive test scenarios:

```bash
# Run all tests
./test-render.sh

# Test specific values file
helm template test-01 . -f test-values/01-simple-web-app.yaml

# Validate against cluster
helm template test-01 . -f test-values/01-simple-web-app.yaml | kubectl apply --dry-run=server -f -
```

See [test-values/README.md](./test-values/README.md) for detailed test documentation.

## Values File Structure

The values file is organized into logical sections:

```yaml
# BASIC CONFIGURATION
nameOverride: ""
fullnameOverride: ""
replicaCount: 1

# IMAGE CONFIGURATION
image: {}
imagePullSecrets: []

# CONTAINER CONFIGURATION
container: {}

# POD CONFIGURATION
initContainers: []
additionalContainers: []
podSecurityContext: {}
podAnnotations: {}
podLabels: {}

# WORKLOAD TYPE
deployment: {}
statefulSet: {}

# NETWORKING
service: {}
ingress: {}
gateway: {}

# STORAGE & CONFIGURATION
persistence: {}
configMaps: {}
secrets: {}
secretMounts: {}

# SCALING & AVAILABILITY
autoscaling: {}
vpa: {}
podDisruptionBudget: {}

# JOBS & SCHEDULING
migrations: {}
cronjobs: {}

# OBSERVABILITY
serviceMonitor: {}

# SECURITY & IDENTITY
serviceAccount: {}

# ADVANCED
reloader: {}
nodeSelector: {}
tolerations: []
affinity: {}
```

## Best Practices

### 1. Use Semantic Versioning for Images

```yaml
image:
  tag: "v1.2.3"  # ✓ Good
  # tag: "latest"  # ✗ Avoid in production
```

### 2. Always Set Resource Requests and Limits

```yaml
container:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### 3. Configure Health Probes

```yaml
container:
  livenessProbe:
    httpGet:
      path: /health
      port: http
  readinessProbe:
    httpGet:
      path: /ready
      port: http
```

### 4. Use Pod Disruption Budgets for Critical Services

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### 5. Separate Configuration from Code

Use ConfigMaps and Secrets instead of baking configuration into images.

### 6. Use Namespaces for Environment Separation

```bash
helm install myapp ./app-starter -f values-prod.yaml -n production
helm install myapp ./app-starter -f values-dev.yaml -n development
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade myapp ./app-starter -f values.yaml

# Upgrade with dry-run
helm upgrade myapp ./app-starter -f values.yaml --dry-run --debug

# Upgrade with diff (requires helm-diff plugin)
helm diff upgrade myapp ./app-starter -f values.yaml
```

## Troubleshooting

### Check Rendered Templates

```bash
helm template myapp ./app-starter -f values.yaml
```

### Validate Against Cluster Schema

```bash
helm template myapp ./app-starter -f values.yaml | kubectl apply --dry-run=server -f -
```

### Debug Helm Rendering Issues

```bash
helm install myapp ./app-starter -f values.yaml --dry-run --debug
```

### Check Generated Resource Names

```bash
helm template myapp ./app-starter -f values.yaml | grep "^  name:"
```

## Contributing

### Adding New Features

1. Update templates in `templates/`
2. Add default values in `values.yaml` with comments
3. Create test case in `test-values/`
4. Run `./test-render.sh` to validate
5. Update this README

### Code Style

- Use 2-space indentation
- Add comments for all configuration options
- Provide examples in values.yaml
- Follow Helm best practices

## License

This chart is provided as-is for use in your Kubernetes deployments.

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Reloader](https://github.com/stakater/Reloader)

