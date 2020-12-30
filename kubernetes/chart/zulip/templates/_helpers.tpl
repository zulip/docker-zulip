
{{- define "zulip.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "zulip.fullname.withName" -}}
{{- default .root.Chart.Name .root.Values.nameOverride | trunc 63 | trimSuffix "-" -}}-{{ .name }}
{{- end }}


{{- define "zulip.selectorLabels.withName" -}}
app.kubernetes.io/name: {{ include "zulip.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}-{{ .name }}
{{- end }}


{{- define "zulip.labels.withName" -}}
helm.sh/chart: {{ include "zulip.chart" .root }}
{{ include "zulip.selectorLabels.withName" . }}
{{- if .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}



{{- define "zulip.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}



{{- define "zulip.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
