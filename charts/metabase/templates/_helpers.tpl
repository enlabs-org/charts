{{/*
Resolve container image. `image` may be a map (repository + tag, empty tag = Chart.appVersion)
or a legacy full image reference string.
*/}}
{{- define "metabase.image" -}}
{{- if kindIs "string" .Values.image -}}
{{- .Values.image -}}
{{- else -}}
{{- $repo := required "image.repository is required" .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
