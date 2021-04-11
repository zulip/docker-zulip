
{{- define "zulip.template.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "zulip.fullname.withName" .}}
  labels:
    {{- include "zulip.labels.withName" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "zulip.selectorLabels.withName" . | nindent 6 }}
  template:
    metadata:
      {{- with .subvalues.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "zulip.selectorLabels.withName" . | nindent 8 }}
    spec:
      {{- with .subvalues.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: {{ .subvalues.image }}
          imagePullPolicy: {{ .subvalues.pullPolicy }}
          {{- with .subvalues.port }}
          ports:
            - containerPort: {{ . }}
          {{- end }}
          {{- with .subvalues.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .subvalues.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .subvalues.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .subvalues.needVolume }}
          volumeMounts:
            - name: {{ .name }}-persistent-storage
              mountPath: {{ .subvalues.mountPath }}
          {{- end }}
      {{- if .subvalues.needVolume }}
      volumes:
        - name: {{ .name }}-persistent-storage
          persistentVolumeClaim:
            claimName: {{ template "zulip.fullname.withName" . }}
      {{- end }}
      {{- with .subvalues.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .subvalues.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .subvalues.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
  {{- end }}
