{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version for chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-specific labels
Usage: {{ include "app.componentLabels" (dict "root" . "componentName" $componentName) }}
*/}}
{{- define "app.componentLabels" -}}
helm.sh/chart: {{ include "app.chart" .root }}
app.kubernetes.io/name: {{ include "app.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .componentName }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}

{{/*
Component-specific selector labels
Usage: {{ include "app.componentSelectorLabels" (dict "root" . "componentName" $componentName) }}
*/}}
{{- define "app.componentSelectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .componentName }}
{{- end }}

{{/*
Component resource name (release-name-component)
Usage: {{ include "app.componentFullname" (dict "releaseName" $.Release.Name "componentName" $componentName) }}
*/}}
{{- define "app.componentFullname" -}}
{{- printf "%s-%s" .releaseName .componentName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get envFromSecret - component-level overrides global
Usage: {{ include "app.envFromSecret" (dict "component" $component "global" $.Values.global) }}
*/}}
{{- define "app.envFromSecret" -}}
{{- if .component.envFromSecret }}
{{- .component.envFromSecret }}
{{- else if .global.envFromSecret }}
{{- .global.envFromSecret }}
{{- end }}
{{- end }}

{{/*
Custom labels - merges global.labels with component.labels
Usage: {{ include "app.customLabels" (dict "global" $.Values.global "component" $component) | nindent 4 }}
*/}}
{{- define "app.customLabels" -}}
{{- $labels := dict }}
{{- if .global.labels }}
{{- $labels = merge $labels .global.labels }}
{{- end }}
{{- if .component }}
{{- if .component.labels }}
{{- $labels = merge $labels .component.labels }}
{{- end }}
{{- end }}
{{- if $labels }}
{{- toYaml $labels }}
{{- end }}
{{- end }}

{{/*
Database cert volume mount
Usage: {{ include "app.databaseCertVolumeMount" $.Values.global | nindent 12 }}
*/}}
{{- define "app.databaseCertVolumeMount" -}}
{{- if .useDatabaseCert }}
- name: database-cert
  mountPath: {{ .databaseCert.mountPath }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
Database cert volume
Usage: {{ include "app.databaseCertVolume" $.Values.global | nindent 8 }}
*/}}
{{- define "app.databaseCertVolume" -}}
{{- if .useDatabaseCert }}
- name: database-cert
  secret:
    secretName: {{ .databaseCert.secretName }}
{{- end }}
{{- end }}
