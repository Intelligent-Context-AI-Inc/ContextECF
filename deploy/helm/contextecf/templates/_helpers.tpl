{{/*
ContextECF Helm chart helpers
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "contextecf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a fully qualified app name.
*/}}
{{- define "contextecf.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create the namespace name.
*/}}
{{- define "contextecf.namespace" -}}
{{- default .Values.namespace "contextecf" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "contextecf.labels" -}}
app.kubernetes.io/part-of: contextecf
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "contextecf.name" . }}-{{ .Chart.Version }}
{{- if .Values.global.tenantId }}
contextecf.io/tenant-id: {{ .Values.global.tenantId | quote }}
{{- end }}
{{- if .Values.global.environment }}
contextecf.io/environment: {{ .Values.global.environment | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels for a specific service.
*/}}
{{- define "contextecf.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/part-of: contextecf
{{- end }}

{{/*
Image reference for a service.
*/}}
{{- define "contextecf.image" -}}
{{- printf "%s/%s:%s" .global.imageRegistry .name .global.imageTag }}
{{- end }}
