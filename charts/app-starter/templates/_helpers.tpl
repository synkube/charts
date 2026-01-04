{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "app-starter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app-starter.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app-starter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels - immutable labels for pod selection
These should NEVER include version, chart, or managed-by as they can't change after creation
*/}}
{{- define "app-starter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app-starter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels - includes all metadata labels
*/}}
{{- define "app-starter.labels" -}}
helm.sh/chart: {{ include "app-starter.chart" . }}
{{ include "app-starter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{- define "app-starter.job.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- if not .Values.migrations.randomizeJobName -}}
{{- $hash := printf "%s-%s" .Values.image.repository .Values.image.tag | sha256sum | trunc 5 -}}
{{- printf "%s-%s-job" .Values.fullnameOverride $hash | lower | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $rand := randAlphaNum 5 | lower -}}
{{- printf "%s-%s-job" .Values.fullnameOverride $rand | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if not .Values.migrations.randomizeJobName -}}
{{- $hash := printf "%s-%s" .Values.image.repository .Values.image.tag | sha256sum | trunc 5 -}}
{{- printf "%s-%s-%s-job" .Release.Name $name $hash | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $rand := randAlphaNum 5 | lower -}}
{{- printf "%s-%s-%s-job" .Release.Name $name $rand | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{- define "app-starter.job.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-job-%s" .Release.Name $name  | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either app-starter.fullname if serviceAccount.create is true or default otherwise.
*/}}
{{- define "app-starter.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create -}}
        {{- if (empty .Values.serviceAccount.name) -}}
          {{- printf "%s-controller" (include "app-starter.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Merge container.env, container.envMap, and container.extraEnv variables, removing duplicates.
Precedence order (lowest to highest): container.env → container.envMap → container.extraEnv
This allows envMap to be properly merged across multiple values files (Helm merges maps but replaces arrays).

Supports two formats for container.envMap:
- Simple string: VAR1: "value1"
- Complex object: VAR1: { value: "value1" } or VAR1: { valueFrom: {...} }

Output is sorted by environment variable name to ensure deterministic ordering.
*/}}

{{- define "app-starter.mergedEnv" -}}
{{- $envMap := dict -}}
{{- $root := . -}}
{{- /* Process container.env array */ -}}
{{- range .Values.container.env -}}
  {{- $envEntry := . -}}
  {{- /* Apply tpl to .value if it exists and is a string */ -}}
  {{- if and (hasKey . "value") (kindIs "string" .value) -}}
    {{- $templatedValue := tpl (.value | toString) $root -}}
    {{- $envEntry = merge (dict "value" $templatedValue) (omit . "value") -}}
  {{- end -}}
  {{- $_ := set $envMap .name $envEntry -}}
{{- end -}}
{{- /* Process container.envMap object - convert to array format */ -}}
{{- range $key, $val := .Values.container.envMap -}}
  {{- $envEntry := dict "name" $key -}}
  {{- $isValid := false -}}
  {{- if kindIs "string" $val -}}
    {{- /* Simple string format: VAR1: "value1" - apply tpl */ -}}
    {{- $templatedValue := tpl ($val | toString) $root -}}
    {{- $_ := set $envEntry "value" $templatedValue -}}
    {{- $isValid = true -}}
  {{- else if kindIs "map" $val -}}
    {{- /* Complex object format */ -}}
    {{- if hasKey $val "value" -}}
      {{- /* Apply tpl to value string */ -}}
      {{- $templatedValue := tpl ($val.value | toString) $root -}}
      {{- $_ := set $envEntry "value" $templatedValue -}}
      {{- $isValid = true -}}
    {{- else if hasKey $val "valueFrom" -}}
      {{- /* Do NOT apply tpl to valueFrom - it's a k8s object reference */ -}}
      {{- $_ := set $envEntry "valueFrom" $val.valueFrom -}}
      {{- $isValid = true -}}
    {{- end -}}
  {{- end -}}
  {{- if $isValid -}}
    {{- $_ := set $envMap $key $envEntry -}}
  {{- end -}}
{{- end -}}
{{- /* Process container.extraEnv array */ -}}
{{- range .Values.container.extraEnv -}}
  {{- $envEntry := . -}}
  {{- /* Apply tpl to .value if it exists and is a string */ -}}
  {{- if and (hasKey . "value") (kindIs "string" .value) -}}
    {{- $templatedValue := tpl (.value | toString) $root -}}
    {{- $envEntry = merge (dict "value" $templatedValue) (omit . "value") -}}
  {{- end -}}
  {{- $_ := set $envMap .name $envEntry -}}
{{- end -}}
{{- /* Sort by key name to ensure deterministic ordering */ -}}
{{- $sortedKeys := keys $envMap | sortAlpha -}}
{{- $sortedEnv := list -}}
{{- range $sortedKeys -}}
  {{- $sortedEnv = append $sortedEnv (get $envMap .) -}}
{{- end -}}
{{- $sortedEnv | toYaml -}}
{{- end -}}

{{/*
Old version without templating support - kept for reference
*/}}
{{- define "app-starter.mergedEnvOld" -}}
{{- $envMap := dict -}}
{{- /* Process container.env array */ -}}
{{- range .Values.container.env -}}
  {{- $_ := set $envMap .name . -}}
{{- end -}}
{{- /* Process container.envMap object - convert to array format */ -}}
{{- range $key, $val := .Values.container.envMap -}}
  {{- $envEntry := dict "name" $key -}}
  {{- $isValid := false -}}
  {{- if kindIs "string" $val -}}
    {{- /* Simple string format: VAR1: "value1" */ -}}
    {{- $_ := set $envEntry "value" $val -}}
    {{- $isValid = true -}}
  {{- else if kindIs "map" $val -}}
    {{- /* Complex object format */ -}}
    {{- if hasKey $val "value" -}}
      {{- $_ := set $envEntry "value" $val.value -}}
      {{- $isValid = true -}}
    {{- else if hasKey $val "valueFrom" -}}
      {{- $_ := set $envEntry "valueFrom" $val.valueFrom -}}
      {{- $isValid = true -}}
    {{- end -}}
  {{- end -}}
  {{- if $isValid -}}
    {{- $_ := set $envMap $key $envEntry -}}
  {{- end -}}
{{- end -}}
{{- /* Process container.extraEnv array */ -}}
{{- range .Values.container.extraEnv -}}
  {{- $_ := set $envMap .name . -}}
{{- end -}}
{{- /* Sort by key name to ensure deterministic ordering */ -}}
{{- $sortedKeys := keys $envMap | sortAlpha -}}
{{- $sortedEnv := list -}}
{{- range $sortedKeys -}}
  {{- $sortedEnv = append $sortedEnv (get $envMap .) -}}
{{- end -}}
{{- $sortedEnv | toYaml -}}
{{- end -}}


{{/*
Reloader annotations - for automatic pod restart on config/secret changes
Requires Reloader operator: https://github.com/stakater/Reloader
*/}}
{{- define "app-starter.reloaderAnnotations" -}}
{{- if .Values.reloader.enabled }}
{{- if .Values.reloader.secretOnly }}
secret.reloader.stakater.com/auto: "true"
{{- else if .Values.reloader.configMapOnly }}
configmap.reloader.stakater.com/auto: "true"
{{- else }}
reloader.stakater.com/auto: "true"
{{- end }}
{{- end }}
{{- end -}}


{{/*
Config checksum annotations - manual pod restart trigger (alternative to Reloader)
Only includes resources that are actually mounted in the pod
*/}}
{{- define "app-starter.configChecksums" -}}
{{- if .Values.secrets }}
checksum/secret: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end }}
{{- if .Values.configMaps }}
checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- end -}}
