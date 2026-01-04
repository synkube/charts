{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Check if a custom resource should be rendered
Returns non-empty if should render, empty if not

Usage: {{ if include "common.hasApi" (list "external-secrets.io/v1/ExternalSecret" .) }}

The function will render resources if:
1. global.skipApiCheck is true (for testing/CI) OR
2. No capabilities available (offline mode) OR
3. No APIVersions available (offline mode) OR
4. The specific API resource is available in the cluster
*/}}
{{- define "common.hasApi" -}}
{{- $api := index . 0 -}}
{{- $ctx := index . 1 -}}
{{- $skipCheck := false -}}
{{- if $ctx.Values.global -}}
  {{- if $ctx.Values.global.skipApiCheck -}}
    {{- $skipCheck = true -}}
  {{- end -}}
{{- end -}}
{{- if or $skipCheck (not $ctx.Capabilities) (not $ctx.Capabilities.APIVersions) ($ctx.Capabilities.APIVersions.Has $api) -}}
render
{{- end -}}
{{- end }}

{{/*
Generate a safe name for Kubernetes resources
Truncates and ensures valid DNS-1123 subdomain format
*/}}
{{- define "common.safeName" -}}
{{- $name := . -}}
{{- $name | lower | replace "_" "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate resource limits and requests
Usage: {{ include "common.resources" .Values.resources }}
*/}}
{{- define "common.resources" -}}
{{- if . -}}
resources:
  {{- if .limits }}
  limits:
    {{- range $key, $value := .limits }}
    {{ $key }}: {{ $value }}
    {{- end }}
  {{- end }}
  {{- if .requests }}
  requests:
    {{- range $key, $value := .requests }}
    {{ $key }}: {{ $value }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate image pull secrets
Usage: {{ include "common.imagePullSecrets" .Values.imagePullSecrets }}
*/}}
{{- define "common.imagePullSecrets" -}}
{{- if . -}}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Render environment variables
Usage: {{ include "common.env" .Values.env }}
*/}}
{{- define "common.env" -}}
{{- if . -}}
env:
  {{- range $key, $value := . }}
  - name: {{ $key | quote }}
    {{- if kindIs "string" $value }}
    value: {{ $value | quote }}
    {{- else if $value.valueFrom }}
    valueFrom:
      {{- toYaml $value.valueFrom | nindent 6 }}
    {{- else }}
    value: {{ $value | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Determine if running in a specific namespace
Usage: {{ if include "common.inNamespace" (list "kube-system" .) }}
*/}}
{{- define "common.inNamespace" -}}
{{- $targetNamespace := index . 0 -}}
{{- $ctx := index . 1 -}}
{{- if eq $ctx.Release.Namespace $targetNamespace -}}
true
{{- end -}}
{{- end }}

{{/*
Generate a configmap checksum for pod restart on config change
Usage: {{ include "common.configChecksum" (dict "configMap" "my-config" "context" .) }}
*/}}
{{- define "common.configChecksum" -}}
{{- $configMapName := .configMap -}}
{{- $ctx := .context -}}
checksum/config: {{ include (printf "%s" $configMapName) $ctx | sha256sum }}
{{- end }}
