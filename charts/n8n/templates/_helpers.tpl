{{/*
Resolve the full container image reference.
Supports two input formats for .Values.image:
  - string: used verbatim
  - object: `{repository, tag}` — tag defaults to .Chart.AppVersion
Usage: {{ include "n8n.image" . }}
*/}}
{{- define "n8n.image" -}}
{{- if kindIs "string" .Values.image -}}
{{- .Values.image -}}
{{- else -}}
{{- $repo := required "image.repository is required" .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}

{{/*
Resolve imagePullPolicy.
Priority: image.pullPolicy (new) > imagePullPolicy (legacy) > Always.
Usage: {{ include "n8n.imagePullPolicy" . }}
*/}}
{{- define "n8n.imagePullPolicy" -}}
{{- $policy := "" -}}
{{- if kindIs "map" .Values.image -}}
{{- $policy = .Values.image.pullPolicy | default "" -}}
{{- end -}}
{{- if not $policy -}}
{{- $policy = .Values.imagePullPolicy | default "Always" -}}
{{- end -}}
{{- $policy -}}
{{- end -}}
