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

{{/*
Affinity configuration - merges global and component-level settings
Usage: {{ include "app.affinity" (dict "root" $ "componentName" $componentName "component" $component) }}
*/}}
{{- define "app.affinity" -}}
{{- $global := .root.Values.global }}
{{- $component := .component }}
{{- $componentName := .componentName }}

{{- /* Component affinity overrides global, null disables */ -}}
{{- $affinity := dict }}
{{- if $global.affinity }}
{{- $affinity = $global.affinity }}
{{- end }}
{{- if hasKey $component "affinity" }}
{{- if $component.affinity }}
{{- $affinity = $component.affinity }}
{{- else }}
{{- $affinity = dict }}
{{- end }}
{{- end }}

{{- if $affinity }}
{{- $result := dict }}

{{- if $affinity.nodeAffinity }}
{{- $nodeAff := include "app.affinity.node" (dict "config" $affinity.nodeAffinity) | fromYaml }}
{{- if $nodeAff }}
{{- $_ := set $result "nodeAffinity" $nodeAff }}
{{- end }}
{{- end }}

{{- if $affinity.podAntiAffinity }}
{{- $podAntiAff := include "app.affinity.podAnti" (dict "root" .root "componentName" $componentName "config" $affinity.podAntiAffinity) | fromYaml }}
{{- if $podAntiAff }}
{{- $_ := set $result "podAntiAffinity" $podAntiAff }}
{{- end }}
{{- end }}

{{- if $affinity.podAffinity }}
{{- $podAff := include "app.affinity.pod" (dict "root" .root "componentName" $componentName "config" $affinity.podAffinity) | fromYaml }}
{{- if $podAff }}
{{- $_ := set $result "podAffinity" $podAff }}
{{- end }}
{{- end }}

{{- if $result }}
{{- toYaml $result }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Node affinity builder
Usage: {{ include "app.affinity.node" (dict "config" $nodeAffinityConfig) }}
*/}}
{{- define "app.affinity.node" -}}
{{- $config := .config }}

{{- if $config.custom }}
{{- toYaml $config.custom }}
{{- else if or $config.requiredNodeLabels $config.preferredNodeLabels }}
{{- $result := dict }}

{{- if $config.requiredNodeLabels }}
{{- $matchExpressions := list }}
{{- range $key, $value := $config.requiredNodeLabels }}
{{- $matchExpressions = append $matchExpressions (dict "key" $key "operator" "In" "values" (list $value)) }}
{{- end }}
{{- $required := dict "nodeSelectorTerms" (list (dict "matchExpressions" $matchExpressions)) }}
{{- $_ := set $result "requiredDuringSchedulingIgnoredDuringExecution" $required }}
{{- end }}

{{- if $config.preferredNodeLabels }}
{{- $preferred := list }}
{{- range $key, $value := $config.preferredNodeLabels }}
{{- $matchExpressions := list (dict "key" $key "operator" "In" "values" (list $value)) }}
{{- $term := dict "weight" 100 "preference" (dict "matchExpressions" $matchExpressions) }}
{{- $preferred = append $preferred $term }}
{{- end }}
{{- $_ := set $result "preferredDuringSchedulingIgnoredDuringExecution" $preferred }}
{{- end }}

{{- toYaml $result }}
{{- end }}
{{- end }}

{{/*
Pod anti-affinity builder
Usage: {{ include "app.affinity.podAnti" (dict "root" $ "componentName" $name "config" $config) }}
*/}}
{{- define "app.affinity.podAnti" -}}
{{- $root := .root }}
{{- $componentName := .componentName }}
{{- $config := .config }}

{{- if $config.custom }}
{{- toYaml $config.custom }}
{{- else }}
{{- $result := dict }}
{{- $required := list }}
{{- $preferred := list }}

{{- if $config.requiredSpreadBy }}
{{- range $config.requiredSpreadBy }}
{{- $labels := include "app.componentSelectorLabels" (dict "root" $root "componentName" $componentName) | fromYaml }}
{{- $term := dict "topologyKey" . "labelSelector" (dict "matchLabels" $labels) }}
{{- $required = append $required $term }}
{{- end }}
{{- end }}

{{- if $config.preferredSpreadBy }}
{{- range $config.preferredSpreadBy }}
{{- $labels := include "app.componentSelectorLabels" (dict "root" $root "componentName" $componentName) | fromYaml }}
{{- $term := dict "weight" 100 "podAffinityTerm" (dict "topologyKey" . "labelSelector" (dict "matchLabels" $labels)) }}
{{- $preferred = append $preferred $term }}
{{- end }}
{{- end }}

{{- if $config.avoidComponents }}
{{- range $config.avoidComponents }}
{{- $labels := include "app.componentSelectorLabels" (dict "root" $root "componentName" .) | fromYaml }}
{{- $term := dict "weight" 100 "podAffinityTerm" (dict "topologyKey" "kubernetes.io/hostname" "labelSelector" (dict "matchLabels" $labels)) }}
{{- $preferred = append $preferred $term }}
{{- end }}
{{- end }}

{{- if $required }}
{{- $_ := set $result "requiredDuringSchedulingIgnoredDuringExecution" $required }}
{{- end }}
{{- if $preferred }}
{{- $_ := set $result "preferredDuringSchedulingIgnoredDuringExecution" $preferred }}
{{- end }}

{{- if $result }}
{{- toYaml $result }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Pod affinity builder
Usage: {{ include "app.affinity.pod" (dict "root" $ "componentName" $name "config" $config) }}
*/}}
{{- define "app.affinity.pod" -}}
{{- $root := .root }}
{{- $componentName := .componentName }}
{{- $config := .config }}

{{- if $config.custom }}
{{- toYaml $config.custom }}
{{- else }}
{{- $result := dict }}
{{- $required := list }}
{{- $preferred := list }}

{{- if $config.requireComponents }}
{{- range $config.requireComponents }}
{{- $labels := include "app.componentSelectorLabels" (dict "root" $root "componentName" .) | fromYaml }}
{{- $term := dict "topologyKey" "kubernetes.io/hostname" "labelSelector" (dict "matchLabels" $labels) }}
{{- $required = append $required $term }}
{{- end }}
{{- end }}

{{- if $config.preferComponents }}
{{- range $config.preferComponents }}
{{- $labels := include "app.componentSelectorLabels" (dict "root" $root "componentName" .) | fromYaml }}
{{- $term := dict "weight" 100 "podAffinityTerm" (dict "topologyKey" "kubernetes.io/hostname" "labelSelector" (dict "matchLabels" $labels)) }}
{{- $preferred = append $preferred $term }}
{{- end }}
{{- end }}

{{- if $required }}
{{- $_ := set $result "requiredDuringSchedulingIgnoredDuringExecution" $required }}
{{- end }}
{{- if $preferred }}
{{- $_ := set $result "preferredDuringSchedulingIgnoredDuringExecution" $preferred }}
{{- end }}

{{- if $result }}
{{- toYaml $result }}
{{- end }}
{{- end }}
{{- end }}
