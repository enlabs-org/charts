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
Resolve securityPathFilter - component-level overrides global
Usage: {{ include "app.securityPathFilter" (dict "component" $component "global" $.Values.global) }}
Returns the resolved securityPathFilter config as YAML, or empty string if disabled/not set.
*/}}
{{- define "app.securityPathFilter" -}}
{{- $filter := dict }}
{{- if .global.securityPathFilter }}
{{- $filter = .global.securityPathFilter }}
{{- end }}
{{- if .component.ingress }}
{{- if hasKey .component.ingress "securityPathFilter" }}
{{- if .component.ingress.securityPathFilter }}
{{- $filter = .component.ingress.securityPathFilter }}
{{- else }}
{{- $filter = dict }}
{{- end }}
{{- end }}
{{- end }}
{{- if and $filter (kindIs "map" $filter) }}
{{- if $filter.enabled }}
{{- toYaml $filter }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Pod-level securityContext resolver.
Component-level `podSecurityContext` overrides `global.podSecurityContext`.
An explicit null on the component disables the inherited global value.
Usage: {{ include "app.podSecurityContext" (dict "component" $component "global" $.Values.global) }}
Returns YAML of the merged/chosen securityContext, or empty string when nothing applies.
*/}}
{{- define "app.podSecurityContext" -}}
{{- $ctx := dict }}
{{- if .global.podSecurityContext }}
{{- $ctx = .global.podSecurityContext }}
{{- end }}
{{- if hasKey .component "podSecurityContext" }}
{{- if .component.podSecurityContext }}
{{- $ctx = .component.podSecurityContext }}
{{- else }}
{{- $ctx = dict }}
{{- end }}
{{- end }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Container-level securityContext resolver.
Per-container `securityContext` overrides `global.securityContext`.
An explicit null on the container disables the inherited global value.
Usage: {{ include "app.securityContext" (dict "container" $container "global" $.Values.global) }}
Where $container is a component (main), initContainer, additionalContainer, job or cronJob entry.
Returns YAML of the merged/chosen securityContext, or empty string when nothing applies.
*/}}
{{- define "app.securityContext" -}}
{{- $ctx := dict }}
{{- if .global.securityContext }}
{{- $ctx = .global.securityContext }}
{{- end }}
{{- if hasKey .container "securityContext" }}
{{- if .container.securityContext }}
{{- $ctx = .container.securityContext }}
{{- else }}
{{- $ctx = dict }}
{{- end }}
{{- end }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Container command renderer.
Backward-compatible with the existing string form (wrapped in `sh -c "..."`),
plus a new list form that is passed straight through as a K8s command array
(does NOT replace ENTRYPOINT via a shell). Use the list form together with
`args:` when the container image already has a proper ENTRYPOINT (s6-overlay,
tini, wrapper scripts, etc.) and you only want to override the CMD.
Usage: {{ include "app.command" $cmd | nindent 12 }}
*/}}
{{- define "app.command" -}}
{{- if kindIs "slice" . }}
command:
{{- range . }}
  - {{ . | quote }}
{{- end }}
{{- else }}
command: ['sh', '-c', {{ . | quote }}]
{{- end }}
{{- end }}

{{/*
Check if ingress class is traefik
Usage: {{ include "app.isTraefik" (dict "className" $component.ingress.className "globalClassName" $.Values.global.ingressClassName) }}
Returns "true" if traefik, empty string otherwise.
*/}}
{{- define "app.isTraefik" -}}
{{- $className := .className | default .globalClassName | default "nginx" -}}
{{- if eq $className "traefik" -}}true{{- end -}}
{{- end -}}

{{/*
PVC name for a component-level persistence entry.
Auto-generated PVCs are named {release}-{component}-{persistenceName}.
Usage: {{ include "app.componentPvcName" (dict "releaseName" $.Release.Name "componentName" $name "persistenceName" .name) }}
*/}}
{{- define "app.componentPvcName" -}}
{{- printf "%s-%s-%s" .releaseName .componentName .persistenceName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Volume mounts for all persistence entries of a component.
Usage: {{ include "app.persistenceVolumeMounts" $component.persistence | nindent 12 }}
*/}}
{{- define "app.persistenceVolumeMounts" -}}
{{- range . }}
- name: {{ .name }}
  mountPath: {{ required "persistence[].mountPath is required" .mountPath }}
  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
  {{- if .readOnly }}
  readOnly: {{ .readOnly }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Pod-level volumes for all persistence entries of a component.
Each entry becomes a persistentVolumeClaim volume - either auto-created or existingClaim.
Usage: {{ include "app.persistenceVolumes" (dict "releaseName" $.Release.Name "componentName" $componentName "persistence" $component.persistence) | nindent 8 }}
*/}}
{{- define "app.persistenceVolumes" -}}
{{- $releaseName := .releaseName }}
{{- $componentName := .componentName }}
{{- range .persistence }}
- name: {{ .name }}
  persistentVolumeClaim:
    {{- if .existingClaim }}
    claimName: {{ .existingClaim }}
    {{- else }}
    claimName: {{ include "app.componentPvcName" (dict "releaseName" $releaseName "componentName" $componentName "persistenceName" .name) }}
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
