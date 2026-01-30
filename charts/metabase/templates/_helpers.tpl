{{/*
Expand the name of the chart.
*/}}
{{- define "metabase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "metabase.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version for chart label.
*/}}
{{- define "metabase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metabase.labels" -}}
helm.sh/chart: {{ include "metabase.chart" . }}
{{ include "metabase.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metabase.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metabase.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-specific labels
Usage: {{ include "metabase.componentLabels" (dict "root" . "componentName" $componentName) }}
*/}}
{{- define "metabase.componentLabels" -}}
helm.sh/chart: {{ include "metabase.chart" .root }}
app.kubernetes.io/name: {{ include "metabase.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .componentName }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}

{{/*
Component-specific selector labels
Usage: {{ include "metabase.componentSelectorLabels" (dict "root" . "componentName" $componentName) }}
*/}}
{{- define "metabase.componentSelectorLabels" -}}
app.kubernetes.io/name: {{ include "metabase.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .componentName }}
{{- end }}

{{/*
Component resource name (release-name-component)
Usage: {{ include "metabase.componentFullname" (dict "releaseName" $.Release.Name "componentName" $componentName) }}
*/}}
{{- define "metabase.componentFullname" -}}
{{- printf "%s-%s" .releaseName .componentName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get envFromSecret - component-level overrides global
Usage: {{ include "metabase.envFromSecret" (dict "component" $component "global" $.Values.global) }}
*/}}
{{- define "metabase.envFromSecret" -}}
{{- if .component.envFromSecret }}
{{- .component.envFromSecret }}
{{- else if .global.envFromSecret }}
{{- .global.envFromSecret }}
{{- end }}
{{- end }}

{{/*
Custom labels - merges global.labels with component.labels
Usage: {{ include "metabase.customLabels" (dict "global" $.Values.global "component" $component) | nindent 4 }}
*/}}
{{- define "metabase.customLabels" -}}
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
Usage: {{ include "metabase.databaseCertVolumeMount" $.Values.global | nindent 12 }}
*/}}
{{- define "metabase.databaseCertVolumeMount" -}}
{{- if .useDatabaseCert }}
- name: database-cert
  mountPath: {{ .databaseCert.mountPath }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
Database cert volume
Usage: {{ include "metabase.databaseCertVolume" $.Values.global | nindent 8 }}
*/}}
{{- define "metabase.databaseCertVolume" -}}
{{- if .useDatabaseCert }}
- name: database-cert
  secret:
    secretName: {{ .databaseCert.secretName }}
{{- end }}
{{- end }}