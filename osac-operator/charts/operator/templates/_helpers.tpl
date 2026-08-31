{{/*
Expand the name of the chart.
*/}}
{{- define "osac-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "osac-operator.fullname" -}}
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
Common labels
*/}}
{{- define "osac-operator.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "osac-operator.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "osac-operator.selectorLabels" -}}
control-plane: controller-manager
app.kubernetes.io/name: {{ include "osac-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Console proxy labels
*/}}
{{- define "osac-operator.consoleProxy.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "osac-operator.consoleProxy.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Console proxy selector labels
*/}}
{{- define "osac-operator.consoleProxy.selectorLabels" -}}
app: {{ printf "%s-console-proxy" (include "osac-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "osac-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: console-proxy
{{- end }}

{{/*
Service account name
*/}}
{{- define "osac-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- include "osac-operator.fullname" . }}
{{- end }}
{{- end }}

{{/*
Enable clusterOrder controller based on global.services.caas.enabled or local override
*/}}
{{- define "osac-operator.controller.clusterOrder" -}}
{{- if .Values.controllers.clusterOrder | kindIs "invalid" | not -}}
{{- .Values.controllers.clusterOrder -}}
{{- else -}}
{{- $caasEnabled := true -}}
{{- if .Values.global.services -}}
{{- if .Values.global.services.caas -}}
{{- if hasKey .Values.global.services.caas "enabled" -}}
{{- $caasEnabled = .Values.global.services.caas.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $caasEnabled -}}
{{- end -}}
{{- end }}

{{/*
Enable computeInstance controller based on global.services.vmaas.enabled or local override
*/}}
{{- define "osac-operator.controller.computeInstance" -}}
{{- if .Values.controllers.computeInstance | kindIs "invalid" | not -}}
{{- .Values.controllers.computeInstance -}}
{{- else -}}
{{- $vmaasEnabled := true -}}
{{- if .Values.global.services -}}
{{- if .Values.global.services.vmaas -}}
{{- if hasKey .Values.global.services.vmaas "enabled" -}}
{{- $vmaasEnabled = .Values.global.services.vmaas.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $vmaasEnabled -}}
{{- end -}}
{{- end }}

{{/*
Enable bareMetalInstance controller based on global.services.bmaas.enabled or local override
*/}}
{{- define "osac-operator.controller.bareMetalInstance" -}}
{{- if .Values.controllers.bareMetalInstance | kindIs "invalid" | not -}}
{{- .Values.controllers.bareMetalInstance -}}
{{- else -}}
{{- $bmaasEnabled := true -}}
{{- if .Values.global.services -}}
{{- if .Values.global.services.bmaas -}}
{{- if hasKey .Values.global.services.bmaas "enabled" -}}
{{- $bmaasEnabled = .Values.global.services.bmaas.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $bmaasEnabled -}}
{{- end -}}
{{- end }}
