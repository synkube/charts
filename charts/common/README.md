# common

Shared Helm template library for synkube charts.

## What It Does

Provides reusable template helpers:

- `common.name` - Chart name (truncated to 63 chars)
- `common.fullname` - Release-qualified name
- `common.chart` - Chart name and version
- `common.labels` - Standard Kubernetes labels
- `common.selectorLabels` - Pod selector labels
- `common.hasApi` - Check if CRD/API is available
- `common.safeName` - DNS-1123 compliant naming
- `common.resources` - Generate resource limits/requests
- `common.imagePullSecrets` - Image pull secret list
- `common.env` - Environment variable rendering
- `common.inNamespace` - Namespace check helper
- `common.configChecksum` - ConfigMap change detection

## Usage

Add as a dependency in your `Chart.yaml`:

```yaml
dependencies:
  - name: common
    version: "1.x.x"
    repository: "https://synkube.github.io/charts"
```

Then use in templates:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
```

### API Availability Check

Conditionally render CRDs:

```yaml
{{- if include "common.hasApi" (list "external-secrets.io/v1/ExternalSecret" .) }}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
# ...
{{- end }}
```

Skip check for CI/testing:

```yaml
global:
  skipApiCheck: true
```
