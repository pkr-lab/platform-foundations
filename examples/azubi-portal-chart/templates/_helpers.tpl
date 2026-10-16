{{- define "azubi-portal.labels" -}}
app: azubi-portal
app.kubernetes.io/name: azubi-portal
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "azubi-portal.selectorLabels" -}}
app: azubi-portal
{{- end -}}
