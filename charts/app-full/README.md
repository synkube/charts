# app-full

Complete application chart bundling workloads, namespace resources, and cluster resources.

## Overview

`app-full` combines three charts into one:

| Component | Purpose | Default |
|-----------|---------|---------|
| **app-starter** | Workloads (Deployment, Service, Ingress) | Always enabled |
| **app-extensions** | Namespace resources (Secrets, Roles, PVCs) | Disabled |
| **platform-extensions** | Cluster resources (ClusterRoles, Webhooks) | Disabled |

## Install

```bash
# From OCI registry
helm install my-app oci://ghcr.io/synkube/charts/app-full -f values.yaml

# From Helm repository
helm repo add synkube https://synkube.github.io/charts
helm install my-app synkube/app-full -f values.yaml
```

## Quick Examples

### Simple Application (app-starter only)

```yaml
app-starter:
  image:
    repository: myorg/myapp
    tag: v1.0.0
  container:
    ports:
      - name: http
        containerPort: 8080
  service:
    ports:
      - port: 80
        targetPort: 8080
        name: http
  ingress:
    enabled: true
    className: traefik
    hosts:
      - host: myapp.example.com
        paths: ["/"]
```

### Application with Secrets & RBAC (+ app-extensions)

```yaml
app-starter:
  image:
    repository: myorg/api-server
    tag: v2.1.0
  container:
    ports:
      - name: http
        containerPort: 8080
    env:
      - name: DATABASE_URL
        valueFrom:
          secretKeyRef:
            name: api-secrets
            key: database-url
      - name: REDIS_URL
        valueFrom:
          secretKeyRef:
            name: api-secrets
            key: redis-url
  serviceAccount:
    create: true
    name: api-server

app-extensions:
  enabled: true

  # Sync secrets from external provider (Vault, AWS SM, Infisical, etc.)
  externalSecrets:
    api-secrets:
      refreshInterval: 1h
      secretStoreRef:
        name: infisical       # Your ClusterSecretStore
        kind: ClusterSecretStore
      target:
        name: api-secrets
        creationPolicy: Owner
      data:
        - secretKey: database-url
          remoteRef:
            key: /prod/api/database-url
        - secretKey: redis-url
          remoteRef:
            key: /prod/api/redis-url
        - secretKey: api-key
          remoteRef:
            key: /prod/api/api-key

  # Namespace-scoped RBAC for the app
  roles:
    api-server:
      rules:
        - apiGroups: [""]
          resources: [secrets, configmaps]
          verbs: [get, list, watch]
        - apiGroups: [""]
          resources: [pods]
          verbs: [get, list]

  roleBindings:
    api-server:
      subjects:
        - kind: ServiceAccount
          name: api-server
      roleRef:
        kind: Role
        name: api-server
        apiGroup: rbac.authorization.k8s.io
```

### Platform Service with ClusterRole (+ platform-extensions)

```yaml
app-starter:
  image:
    repository: ghcr.io/gethomepage/homepage
    tag: v1.2.0
  serviceAccount:
    create: true
    name: homepage

platform-extensions:
  enabled: true
  clusterRoles:
    homepage:
      rules:
        - apiGroups: [""]
          resources: [namespaces, pods, services]
          verbs: [get, list]
        - apiGroups: [networking.k8s.io]
          resources: [ingresses]
          verbs: [get, list]
  clusterRoleBindings:
    homepage:
      subjects:
        - kind: ServiceAccount
          name: homepage
          namespace: '{{ .Release.Namespace }}'
      roleRef:
        kind: ClusterRole
        name: homepage
```

## Component Documentation

- [app-starter](https://github.com/synkube/charts/tree/main/charts/app-starter)
- [app-extensions](https://github.com/synkube/charts/tree/main/charts/app-extensions)
- [platform-extensions](https://github.com/synkube/charts/tree/main/charts/platform-extensions)
