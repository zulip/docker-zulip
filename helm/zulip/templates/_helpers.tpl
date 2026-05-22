{{/*
Expand the name of the chart.
*/}}
{{- define "zulip.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "zulip.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "zulip.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.  Any operator-supplied `commonLabels` whose key clashes
with the chart's own identifying labels (app.kubernetes.io/name,
/instance, /managed-by, /version, helm.sh/chart) is dropped, so the
chart's value always wins -- otherwise an overridden `name` or
`managed-by` would silently break the StatefulSet's selector matching
and Helm's resource tracking.
*/}}
{{- define "zulip.labels" -}}
{{- with omit (.Values.commonLabels | default dict) "helm.sh/chart" "app.kubernetes.io/name" "app.kubernetes.io/instance" "app.kubernetes.io/managed-by" "app.kubernetes.io/version" }}
{{ toYaml . }}
{{- end }}
helm.sh/chart: {{ include "zulip.chart" . }}
{{ include "zulip.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zulip.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zulip.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zulip.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zulip.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
include all env variables for Zulip pods
*/}}
{{- define "zulip.env" -}}

{{/* --- PostgreSQL --- */}}
{{- if .Values.postgresql.enabled }}
- name: SETTING_REMOTE_POSTGRES_HOST
  value: "{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}"
- name: SETTING_REMOTE_POSTGRES_PORT
  value: "{{ template "postgresql.v1.service.port" .Subcharts.postgresql }}"
- name: SECRETS_postgres_password
  {{- if .Values.postgresql.auth.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.auth.existingSecret }}
      key: {{ dig "auth" "secretKeys" "userPasswordKey" "password" .Values.postgresql }}
  {{- else }}
  value: {{ .Values.postgresql.auth.password | quote }}
  {{- end }}
{{- else }}
- name: SETTING_REMOTE_POSTGRES_HOST
  value: {{ required "externalPostgresql.host is required when postgresql.enabled is false" .Values.externalPostgresql.host | quote }}
- name: SETTING_REMOTE_POSTGRES_PORT
  value: {{ .Values.externalPostgresql.port | toString | quote }}
- name: SECRETS_postgres_password
  {{- if kindIs "map" .Values.externalPostgresql.password }}
  {{- toYaml .Values.externalPostgresql.password | nindent 2 }}
  {{- else }}
  value: {{ .Values.externalPostgresql.password | quote }}
  {{- end }}
{{- if .Values.externalPostgresql.sslmode }}
- name: SETTING_REMOTE_POSTGRES_SSLMODE
  value: {{ .Values.externalPostgresql.sslmode | quote }}
{{- end }}
{{- if .Values.externalPostgresql.user }}
- name: CONFIG_postgresql__database_user
  value: {{ .Values.externalPostgresql.user | quote }}
{{- end }}
{{- if .Values.externalPostgresql.database }}
- name: CONFIG_postgresql__database_name
  value: {{ .Values.externalPostgresql.database | quote }}
{{- end }}
{{- end }}

{{/* --- RabbitMQ --- */}}
{{- if .Values.rabbitmq.enabled }}
- name: SETTING_RABBITMQ_HOST
  value: "{{ template "common.names.fullname" .Subcharts.rabbitmq }}"
- name: SETTING_RABBITMQ_USERNAME
  value: "{{ .Values.rabbitmq.auth.username }}"
- name: SECRETS_rabbitmq_password
  {{- if .Values.rabbitmq.auth.existingPasswordSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.rabbitmq.auth.existingPasswordSecret }}
      key: {{ .Values.rabbitmq.auth.existingSecretPasswordKey | default "rabbitmq-password" }}
  {{- else }}
  value: {{ .Values.rabbitmq.auth.password | quote }}
  {{- end }}
{{- else }}
- name: SETTING_RABBITMQ_HOST
  value: {{ required "externalRabbitmq.host is required when rabbitmq.enabled is false" .Values.externalRabbitmq.host | quote }}
- name: SETTING_RABBITMQ_PORT
  value: {{ .Values.externalRabbitmq.port | toString | quote }}
- name: SECRETS_rabbitmq_password
  {{- if kindIs "map" .Values.externalRabbitmq.password }}
  {{- toYaml .Values.externalRabbitmq.password | nindent 2 }}
  {{- else }}
  value: {{ .Values.externalRabbitmq.password | quote }}
  {{- end }}
{{- if .Values.externalRabbitmq.user }}
- name: SETTING_RABBITMQ_USERNAME
  value: {{ .Values.externalRabbitmq.user | quote }}
{{- end }}
{{- end }}

{{/* --- Memcached --- */}}
{{- if .Values.memcached.enabled }}
- name: SETTING_MEMCACHED_LOCATION
  value: "{{ template "common.names.fullname" .Subcharts.memcached }}:11211"
- name: SETTING_MEMCACHED_USERNAME
  value: "{{ .Values.memcached.auth.username }}"
- name: SECRETS_memcached_password
  {{- if .Values.memcached.auth.existingPasswordSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.memcached.auth.existingPasswordSecret }}
      key: {{ .Values.memcached.auth.existingSecretPasswordKey | default "memcached-password" }}
  {{- else }}
  value: {{ .Values.memcached.auth.password | quote }}
  {{- end }}
{{- else }}
- name: SETTING_MEMCACHED_LOCATION
  value: "{{ required "externalMemcached.host is required when memcached.enabled is false" .Values.externalMemcached.host }}:{{ .Values.externalMemcached.port }}"
- name: SECRETS_memcached_password
  {{- if kindIs "map" .Values.externalMemcached.password }}
  {{- toYaml .Values.externalMemcached.password | nindent 2 }}
  {{- else }}
  value: {{ .Values.externalMemcached.password | quote }}
  {{- end }}
{{- if .Values.externalMemcached.user }}
- name: SETTING_MEMCACHED_USERNAME
  value: {{ .Values.externalMemcached.user | quote }}
{{- end }}
{{- end }}

{{/* --- Redis --- */}}
{{- if .Values.redis.enabled }}
- name: SETTING_REDIS_HOST
  value: "{{ template "common.names.fullname" .Subcharts.redis }}-headless"
- name: SECRETS_redis_password
  {{- if .Values.redis.auth.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ .Values.redis.auth.existingSecret }}
      key: {{ .Values.redis.auth.existingSecretPasswordKey | default "redis-password" }}
  {{- else }}
  value: {{ .Values.redis.auth.password | quote }}
  {{- end }}
{{- else }}
- name: SETTING_REDIS_HOST
  value: {{ required "externalRedis.host is required when redis.enabled is false" .Values.externalRedis.host | quote }}
- name: SETTING_REDIS_PORT
  value: {{ .Values.externalRedis.port | toString | quote }}
- name: SECRETS_redis_password
  {{- if kindIs "map" .Values.externalRedis.password }}
  {{- toYaml .Values.externalRedis.password | nindent 2 }}
  {{- else }}
  value: {{ .Values.externalRedis.password | quote }}
  {{- end }}
{{- end }}

{{- range $key, $value := .Values.zulip.environment }}
- name: {{ $key }}
  {{- if kindIs "map" $value }}
  {{- toYaml $value | nindent 2 }}
  {{- else }}
  value: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}
