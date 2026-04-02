{{/*
Generate the full name for a resource.
*/}}
{{- define "legacy-modernization.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels for all resources.
*/}}
{{- define "legacy-modernization.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: legacy-modernization
{{- end -}}

{{/*
Selector labels for a specific system.
*/}}
{{- define "legacy-modernization.selectorLabels" -}}
app: {{ .name }}
{{- end -}}

{{/*
System labels combining common and selector labels.
*/}}
{{- define "legacy-modernization.systemLabels" -}}
{{ include "legacy-modernization.labels" .context }}
app: {{ .name }}
tier: legacy-modernization
{{- if .runtime }}
runtime: {{ .runtime }}
{{- end }}
{{- end -}}
