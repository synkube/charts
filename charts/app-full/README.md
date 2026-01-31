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

### Application with Secrets (+ app-extensions)

```yaml
app-starter:
  image:
    repository: myorg/myapp
    tag: v1.0.0
  container:
    envFromSecretName: myapp-secrets

app-extensions:
  enabled: true
  externalSecrets:
    myapp-secrets:
      secretStoreRef:
        name: vault
        kind: ClusterSecretStore
      data:
        - secretKey: DATABASE_URL
          remoteRef:
            key: myapp/database
            property: url
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
