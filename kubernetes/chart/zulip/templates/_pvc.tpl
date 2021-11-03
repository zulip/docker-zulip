
{{- define "zulip.template.pvc" -}}
{{- if .subvalues.needVolume }}
{{ println "" }}
{{ println "---" }}
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{ include "zulip.fullname.withName" . }}
  labels:
    {{- include "zulip.labels.withName" . | nindent 4 }}
    {{- with .subvalues.persistence.annotations }}
  annotations:
    {{ toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with .subvalues.persistence.selector }}
  selector:
    {{ toYaml . | nindent 4 }}
  {{- end }}
  accessModes:
    - {{ .subvalues.persistence.accessMode | quote }}
  resources:
    requests:
      storage: {{ .subvalues.persistence.size | quote }}
  {{- with .subvalues.persistence.storageClass }}
  storageClassName: "{{ . }}"
  {{- end }}
{{- end }}
{{- end }}
