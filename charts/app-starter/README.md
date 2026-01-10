# App Starter

## Overview
One chart ⎈ to rule them All

A universal Helm chart for deploying any application on Kubernetes. Instead of writing custom charts for each service, use `app-starter` as a flexible foundation that adapts to your needs — from simple web apps to complex stateful services with sidecars, jobs, and autoscaling.

**Why use app-starter?**
- **One chart for everything** — Deploy web apps, APIs, workers, databases, and scheduled jobs
- **Sensible defaults** — Works out of the box with minimal configuration
- **Progressive complexity** — Start minimal, enable features as needed
- **Production patterns built-in** — HPA, PDB, ServiceMonitor, health probes, security contexts
- **Easily extendable** — Add your own resources and configurations, by making this chart a dependency in your own chart

## Installing the Chart

```bash
# From OCI registry
helm install my-app oci://ghcr.io/synkube/charts/app-starter -f values.yaml

# From Helm repository
helm repo add synkube https://synkube.github.io/charts
helm install my-app synkube/app-starter -f values.yaml
```

## Supported Resources

| Category | Resources |
|----------|-----------|
| **Workloads** | Deployment, StatefulSet, Job, CronJob |
| **Networking** | Service, Ingress, HTTPRoute (Gateway API) |
| **Storage** | PersistentVolumeClaim, ConfigMap, Secret |
| **Scaling** | HorizontalPodAutoscaler, VerticalPodAutoscaler, PodDisruptionBudget |
| **Observability** | ServiceMonitor |

## Configuration Examples

### Simple Web Application

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

### Production API Service

```yaml
replicaCount: 3

image:
  repository: myorg/api
  tag: "v2.1.0"

container:
  ports:
    - name: http
      containerPort: 8080
    - name: metrics
      containerPort: 9090
  envMap:
    LOG_LEVEL: info
    ENVIRONMENT: production
  envFromSecretName: api-secrets
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1
      memory: 1Gi

service:
  ports:
    - port: 80
      targetPort: 8080
      name: http
    - port: 9090
      targetPort: 9090
      name: metrics

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.example.com
      paths: ["/"]
  tls:
    - secretName: api-tls
      hosts: [api.example.com]

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

podDisruptionBudget:
  enabled: true
  minAvailable: 2

serviceMonitor:
  enabled: true
  port: metrics
```

## Configuration Details

### Environment Variables

Three formats supported (merged in order, last wins):

```yaml
container:
  # Array format (K8s native, supports valueFrom)
  env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url

  # Map format (readable, good for values merging)
  envMap:
    LOG_LEVEL: info
    PORT: "8080"

  # Load all keys from ConfigMap/Secret
  envFromSecretName: my-secret
  envFromConfigmaps: [shared-config]
```

### Scheduled Tasks (CronJob)

```yaml
cronjobs:
  enabled: true
  cronjob:
    - name: cleanup
      schedule: "0 2 * * *"
      command: ["/app/cleanup.sh"]
    - name: report
      schedule: "0 9 * * 1"
      command: ["/app/report.sh"]
```

### Gateway API (HTTPRoute)

```yaml
gateway:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  hostnames: [api.example.com]
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
```

### Multi-Container Pods

```yaml
initContainers:
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']

additionalContainers:
  - name: log-shipper
    image: fluentd:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log/app
```

## Extending the Chart

Extend `app-starter` in your own chart by adding it as a dependency:

```yaml
# Chart.yaml
dependencies:
  - name: app-starter
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
```

### Multiple Workloads with Aliases

Deploy multiple services from a single chart using aliases:

```yaml
# Chart.yaml
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
```

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
  ingress:
    enabled: true

worker:
  image:
    repository: myorg/worker
    tag: v1.0.0

scheduler:
  image:
    repository: myorg/scheduler
    tag: v1.0.0
  cronjobs:
    enabled: true
    cronjob:
      - name: process
        schedule: "*/5 * * * *"
        command: ["/app/process.sh"]
```

## Documentation

For complete configuration reference, see [docs/CONFIGURATION.md](https://github.com/synkube/charts/blob/main/charts/app-starter/docs/CONFIGURATION.md).
