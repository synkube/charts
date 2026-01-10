# app-extensions

Namespace-scoped Kubernetes resources for application teams.

## What It Does

Deploy common application resources without writing YAML:

- **Secrets** - Regular K8s secrets with templating
- **ExternalSecrets** - Sync from Vault, Infisical, AWS SM, etc.
- **SecretStores** - Namespace-scoped secret providers
- **SealedSecrets** - Encrypted secrets for GitOps
- **ConfigMaps** - Application configuration
- **ServiceAccounts** - Pod identities with IAM annotations
- **Roles & RoleBindings** - Namespace RBAC
- **NetworkPolicies** - Pod traffic rules
- **PersistentVolumeClaims** - Storage requests

## Install

```bash
helm repo add synkube https://synkube.github.io/charts
helm install my-app-ext synkube/app-extensions -f values.yaml
```

## Quick Example

```yaml
secrets:
  db-credentials:
    stringData:
      username: admin
      password: supersecret

externalSecrets:
  api-keys:
    secretStoreRef:
      name: vault
      kind: ClusterSecretStore
    data:
      - secretKey: stripe-key
        remoteRef:
          key: payments/stripe
          property: api_key

configMaps:
  app-config:
    data:
      settings.yaml:
        content: |
          environment: production
          log_level: info

serviceAccounts:
  app-sa:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/app

networkPolicies:
  allow-ingress:
    podSelector:
      matchLabels:
        app: myapp
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                name: ingress-nginx
```

## Requirements

| Dependency | Required For |
|------------|--------------|
| external-secrets-operator | ExternalSecrets, SecretStores |
| sealed-secrets | SealedSecrets |

