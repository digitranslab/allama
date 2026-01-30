{{/*
Allama Helm Chart Helpers
Following patterns from terraform-fargate/modules/ecs/locals.tf
*/}}

{{/*
Chart name
*/}}
{{- define "allama.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name (truncated to 63 chars for K8s naming)
*/}}
{{- define "allama.fullname" -}}
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
Create chart name and version for chart label
*/}}
{{- define "allama.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "allama.labels" -}}
helm.sh/chart: {{ include "allama.chart" . }}
{{ include "allama.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "allama.selectorLabels" -}}
app.kubernetes.io/name: {{ include "allama.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name for Allama workloads
*/}}
{{- define "allama.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- printf "%s-app" (include "allama.fullname" .) -}}
{{- end -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end }}

{{/*
=============================================================================
PostgreSQL Helpers
=============================================================================
*/}}

{{/*
PostgreSQL Host - CloudNativePG uses <name>-rw service for read-write access
*/}}
{{- define "allama.postgres.host" -}}
{{- if .Values.postgres.enabled }}
{{- printf "%s-rw" .Values.postgres.fullnameOverride }}
{{- else if .Values.externalPostgres.enabled }}
{{- .Values.externalPostgres.host }}
{{- else }}
{{- fail "Either postgres.enabled or externalPostgres.enabled must be true" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL Port
*/}}
{{- define "allama.postgres.port" -}}
{{- if .Values.postgres.enabled }}
{{- "5432" }}
{{- else if .Values.externalPostgres.enabled }}
{{- .Values.externalPostgres.port | default "5432" }}
{{- else }}
{{- "5432" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL Database Name
*/}}
{{- define "allama.postgres.database" -}}
{{- if .Values.postgres.enabled }}
{{- "app" }}{{/* CloudNativePG cluster chart creates 'app' database by default */}}
{{- else if .Values.externalPostgres.enabled }}
{{- .Values.externalPostgres.database | default "allama" }}
{{- else }}
{{- "allama" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL SSL Mode
CloudNativePG cluster uses "disable" by default for internal cluster communication
*/}}
{{- define "allama.postgres.sslMode" -}}
{{- if .Values.postgres.enabled }}
{{- "disable" }}
{{- else if .Values.externalPostgres.enabled }}
{{- .Values.externalPostgres.sslMode | default "prefer" }}
{{- else }}
{{- "disable" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL Secret Name - the secret containing username and password
For CloudNativePG, this is auto-generated as <cluster-name>-app
*/}}
{{- define "allama.postgres.secretName" -}}
{{- if .Values.postgres.enabled }}
{{- printf "%s-app" .Values.postgres.fullnameOverride }}
{{- else if .Values.externalPostgres.enabled }}
{{- .Values.externalPostgres.auth.existingSecret }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL TLS CA ConfigMap Name
Returns the name of the ConfigMap containing the CA certificate for TLS verification
*/}}
{{- define "allama.postgres.caConfigMapName" -}}
{{- if and .Values.externalPostgres.enabled .Values.externalPostgres.tls.verifyCA }}
{{- if .Values.externalPostgres.tls.existingConfigMap }}
{{- .Values.externalPostgres.tls.existingConfigMap }}
{{- else if .Values.externalPostgres.tls.caCert }}
{{- printf "%s-postgres-ca" (include "allama.fullname" .) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
PostgreSQL TLS CA Certificate Path
Returns the mount path for the CA certificate file
*/}}
{{- define "allama.postgres.caCertPath" -}}
{{- "/etc/allama/certs/postgres/ca-bundle.pem" }}
{{- end }}

{{/*
PostgreSQL TLS CA Volume
Returns the volume definition for mounting the CA certificate
*/}}
{{- define "allama.postgres.caVolume" -}}
{{- if and .Values.externalPostgres.enabled .Values.externalPostgres.tls.verifyCA (include "allama.postgres.caConfigMapName" .) }}
- name: postgres-ca
  configMap:
    name: {{ include "allama.postgres.caConfigMapName" . }}
    items:
      - key: {{ .Values.externalPostgres.tls.configMapKey | default "ca-bundle.pem" }}
        path: ca-bundle.pem
{{- end }}
{{- end }}

{{/*
PostgreSQL TLS CA Volume Mount
Returns the volume mount definition for the CA certificate
*/}}
{{- define "allama.postgres.caVolumeMount" -}}
{{- if and .Values.externalPostgres.enabled .Values.externalPostgres.tls.verifyCA (include "allama.postgres.caConfigMapName" .) }}
- name: postgres-ca
  mountPath: /etc/allama/certs/postgres
  readOnly: true
{{- end }}
{{- end }}

{{/*
=============================================================================
Redis/Valkey Helpers
=============================================================================
*/}}

{{/*
Redis Host
*/}}
{{- define "allama.redis.host" -}}
{{- if .Values.redis.enabled }}
{{- .Values.redis.fullnameOverride }}
{{- else if .Values.externalRedis.enabled }}
{{- "external" }}{{/* External Redis uses URL from secret */}}
{{- else }}
{{- fail "Either redis.enabled or externalRedis.enabled must be true" }}
{{- end }}
{{- end }}

{{/*
Redis Port
*/}}
{{- define "allama.redis.port" -}}
{{- "6379" }}
{{- end }}

{{/*
Redis Secret Name - for external Redis containing the URL
*/}}
{{- define "allama.redis.secretName" -}}
{{- if .Values.redis.enabled }}
{{- "" }}{{/* Internal Valkey doesn't need a secret for URL */}}
{{- else if .Values.externalRedis.enabled }}
{{- .Values.externalRedis.auth.existingSecret }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
=============================================================================
URL Helpers
=============================================================================
*/}}

{{/*
URL scheme - returns https if TLS is configured, http otherwise
*/}}
{{- define "allama.urlScheme" -}}
{{- if .Values.ingress.tls }}https{{- else }}http{{- end }}
{{- end }}

{{/*
Public App URL - used for browser redirects and public-facing links
*/}}
{{- define "allama.publicAppUrl" -}}
{{- if .Values.urls.publicApp }}
{{- .Values.urls.publicApp }}
{{- else }}
{{- printf "%s://%s" (include "allama.urlScheme" .) .Values.ingress.host }}
{{- end }}
{{- end }}

{{/*
Public API URL - used for external API access
*/}}
{{- define "allama.publicApiUrl" -}}
{{- if .Values.urls.publicApi }}
{{- .Values.urls.publicApi }}
{{- else }}
{{- printf "%s://%s/api" (include "allama.urlScheme" .) .Values.ingress.host }}
{{- end }}
{{- end }}

{{/*
Public S3 URL - used for presigned URLs
*/}}
{{- define "allama.publicS3Url" -}}
{{- if .Values.urls.publicS3 }}
{{- .Values.urls.publicS3 }}
{{- else if .Values.minio.enabled }}
{{- printf "%s://%s/s3" (include "allama.urlScheme" .) .Values.ingress.host }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Internal API URL - used for service-to-service communication
*/}}
{{- define "allama.internalApiUrl" -}}
{{- printf "http://%s-api:8000" (include "allama.fullname" .) }}
{{- end }}

{{/*
Internal Blob Storage URL
*/}}
{{- define "allama.blobStorageEndpoint" -}}
{{- if .Values.allama.blobStorage.endpoint }}
{{- .Values.allama.blobStorage.endpoint }}
{{- else if .Values.externalS3.enabled }}
{{- .Values.externalS3.endpoint | default "" }}
{{- else if .Values.minio.enabled }}
{{- printf "http://%s:9000" .Values.minio.fullnameOverride }}
{{- else }}
{{- fail "allama.blobStorage.endpoint or externalS3.enabled is required when minio is disabled" }}
{{- end }}
{{- end }}

{{/*
Temporal Fullname - mirrors the subchart naming logic
*/}}
{{- define "allama.temporalFullname" -}}
{{- if .Values.temporal.fullnameOverride }}
{{- .Values.temporal.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "temporal" .Values.temporal.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Temporal Cluster URL - supports both subchart and external Temporal
*/}}
{{- define "allama.temporalClusterUrl" -}}
{{- if .Values.temporal.enabled }}
{{- $values := .Values | toYaml | fromYaml -}}
{{- $port := dig "temporal" "server" "frontend" "service" "port" 7233 $values -}}
{{- printf "%s-frontend:%v" (include "allama.temporalFullname" .) $port }}
{{- else if .Values.externalTemporal.enabled }}
{{- required "externalTemporal.clusterUrl is required when using external Temporal" .Values.externalTemporal.clusterUrl }}
{{- else }}
{{- fail "Either temporal.enabled or externalTemporal.enabled must be true" }}
{{- end }}
{{- end }}

{{/*
Temporal Namespace
*/}}
{{- define "allama.temporalNamespace" -}}
{{- if .Values.temporal.enabled }}
{{- $values := .Values | toYaml | fromYaml -}}
{{- $namespaces := dig "temporal" "server" "config" "namespaces" "namespace" list $values -}}
{{- if and $namespaces (gt (len $namespaces) 0) -}}
{{- $namespace := index $namespaces 0 -}}
{{- index $namespace "name" | default "default" -}}
{{- else -}}
{{- "default" -}}
{{- end }}
{{- else if .Values.externalTemporal.enabled }}
{{- .Values.externalTemporal.clusterNamespace | default "default" }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}

{{/*
Temporal Namespace Retention
*/}}
{{- define "allama.temporalNamespaceRetention" -}}
{{- if .Values.temporal.enabled }}
{{- $values := .Values | toYaml | fromYaml -}}
{{- $namespaces := dig "temporal" "server" "config" "namespaces" "namespace" list $values -}}
{{- if and $namespaces (gt (len $namespaces) 0) -}}
{{- $namespace := index $namespaces 0 -}}
{{- index $namespace "retention" | default "720h" -}}
{{- else -}}
{{- "720h" -}}
{{- end }}
{{- else }}
{{- "720h" -}}
{{- end }}
{{- end }}

{{/*
Temporal Queue
*/}}
{{- define "allama.temporalQueue" -}}
{{- if .Values.temporal.enabled }}
{{- "allama-task-queue" }}
{{- else if .Values.externalTemporal.enabled }}
{{- .Values.externalTemporal.clusterQueue | default "allama-task-queue" }}
{{- else }}
{{- "allama-task-queue" }}
{{- end }}
{{- end }}

{{/*
=============================================================================
Environment Variable Helpers
Following the pattern from terraform-fargate locals.tf where env vars are
computed centrally and merged per-service.
=============================================================================
*/}}

{{/*
Common environment variables shared across all backend services
(api, worker, executor)
*/}}
{{- define "allama.featureFlags" -}}
{{- $flags := list -}}
{{- if .Values.allama.featureFlags }}
{{- $flags = append $flags .Values.allama.featureFlags -}}
{{- end }}
{{- if .Values.enterprise.featureFlags }}
{{- $flags = append $flags .Values.enterprise.featureFlags -}}
{{- end }}
{{- join "," $flags -}}
{{- end }}

{{- define "allama.env.common" -}}
{{- if .Values.allama.logLevel }}
- name: LOG_LEVEL
  value: {{ .Values.allama.logLevel | quote }}
{{- end }}
- name: ALLAMA__APP_ENV
  value: {{ .Values.allama.appEnv | quote }}
- name: ALLAMA__FEATURE_FLAGS
  value: {{ include "allama.featureFlags" . | quote }}
{{- end }}

{{/*
Temporal environment variables (shared by api, worker, executor)
*/}}
{{- define "allama.env.temporal" -}}
- name: TEMPORAL__CLUSTER_URL
  value: {{ include "allama.temporalClusterUrl" . | quote }}
- name: TEMPORAL__CLUSTER_NAMESPACE
  value: {{ include "allama.temporalNamespace" . | quote }}
- name: TEMPORAL__CLUSTER_QUEUE
  value: {{ include "allama.temporalQueue" . | quote }}
{{- if .Values.externalTemporal.enabled }}
{{- if .Values.externalTemporal.auth.secretArn }}
- name: TEMPORAL__API_KEY__ARN
  value: {{ .Values.externalTemporal.auth.secretArn | quote }}
{{- else if .Values.externalTemporal.auth.existingSecret }}
- name: TEMPORAL__API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalTemporal.auth.existingSecret }}
      key: apiKey
{{- end }}
{{- end }}
{{- end }}

{{/*
Blob storage environment variables
*/}}
{{- define "allama.env.blobStorage" -}}
{{- $endpoint := include "allama.blobStorageEndpoint" . }}
{{- if $endpoint }}
- name: ALLAMA__BLOB_STORAGE_ENDPOINT
  value: {{ $endpoint | quote }}
{{- end }}
{{- if .Values.allama.blobStorage.buckets.attachments }}
- name: ALLAMA__BLOB_STORAGE_BUCKET_ATTACHMENTS
  value: {{ .Values.allama.blobStorage.buckets.attachments | quote }}
{{- end }}
{{- if .Values.allama.blobStorage.buckets.registry }}
- name: ALLAMA__BLOB_STORAGE_BUCKET_REGISTRY
  value: {{ .Values.allama.blobStorage.buckets.registry | quote }}
{{- end }}
{{- if .Values.minio.enabled }}
{{- /* Use MinIO credentials from the MinIO secret */}}
{{- $minioSecret := .Values.minio.auth.existingSecret | default .Values.minio.fullnameOverride | default (printf "%s-minio" .Release.Name) }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ $minioSecret }}
      key: rootUser
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $minioSecret }}
      key: rootPassword
{{- else if .Values.externalS3.enabled }}
{{- if .Values.externalS3.region }}
- name: AWS_REGION
  value: {{ .Values.externalS3.region | quote }}
- name: AWS_DEFAULT_REGION
  value: {{ .Values.externalS3.region | quote }}
{{- end }}
{{- if .Values.externalS3.auth.existingSecret }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalS3.auth.existingSecret }}
      key: accessKeyId
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalS3.auth.existingSecret }}
      key: secretAccessKey
{{- end }}
{{- end }}
{{- end }}

{{/*
PostgreSQL environment variables
Constructs ALLAMA__DB_URI from computed host/port/database/sslmode and secret credentials
*/}}
{{- define "allama.env.postgres" -}}
{{- $host := include "allama.postgres.host" . }}
{{- $port := include "allama.postgres.port" . }}
{{- $database := include "allama.postgres.database" . }}
{{- $sslMode := include "allama.postgres.sslMode" . }}
{{- if .Values.postgres.enabled }}
{{- $secretName := include "allama.postgres.secretName" . }}
- name: ALLAMA__POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: username
- name: ALLAMA__POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: password
- name: ALLAMA__DB_URI
  value: "postgresql+psycopg://$(ALLAMA__POSTGRES_USER):$(ALLAMA__POSTGRES_PASSWORD)@{{ $host }}:{{ $port }}/{{ $database }}"
{{- else if .Values.externalPostgres.enabled }}
{{- if .Values.externalPostgres.auth.secretArn }}
{{- if .Values.externalPostgres.auth.username }}
- name: ALLAMA__DB_USER
  value: {{ .Values.externalPostgres.auth.username | quote }}
{{- end }}
- name: ALLAMA__DB_PASS__ARN
  value: {{ .Values.externalPostgres.auth.secretArn | quote }}
- name: ALLAMA__DB_ENDPOINT
  value: {{ $host | quote }}
- name: ALLAMA__DB_PORT
  value: {{ $port | quote }}
- name: ALLAMA__DB_NAME
  value: {{ $database | quote }}
- name: ALLAMA__DB_SSLMODE
  value: {{ $sslMode | quote }}
{{- else if .Values.externalPostgres.auth.existingSecret }}
- name: ALLAMA__DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalPostgres.auth.existingSecret }}
      key: username
- name: ALLAMA__DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalPostgres.auth.existingSecret }}
      key: password
- name: ALLAMA__DB_ENDPOINT
  value: {{ $host | quote }}
- name: ALLAMA__DB_PORT
  value: {{ $port | quote }}
- name: ALLAMA__DB_NAME
  value: {{ $database | quote }}
- name: ALLAMA__DB_SSLMODE
  value: {{ $sslMode | quote }}
{{- else }}
{{- fail "externalPostgres.auth.existingSecret or externalPostgres.auth.secretArn is required when using external Postgres" }}
{{- end }}
{{- else }}
{{- fail "PostgreSQL secret name is required" }}
{{- end }}
{{- end }}

{{/*
Redis environment variables
Constructs REDIS_URL from computed host/port or from external secret
*/}}
{{- define "allama.env.redis" -}}
{{- if .Values.redis.enabled }}
{{- $host := include "allama.redis.host" . }}
{{- $port := include "allama.redis.port" . }}
- name: REDIS_URL
  value: "redis://{{ $host }}:{{ $port }}"
{{- else if .Values.externalRedis.enabled }}
{{- if .Values.externalRedis.auth.secretArn }}
- name: REDIS_URL__ARN
  value: {{ .Values.externalRedis.auth.secretArn | quote }}
{{- else if .Values.externalRedis.auth.existingSecret }}
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalRedis.auth.existingSecret }}
      key: url
{{- else }}
{{- fail "externalRedis.auth.existingSecret or externalRedis.auth.secretArn is required when using external Redis" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
API service environment variables
Merges: common + temporal + postgres + redis + api-specific
*/}}
{{- define "allama.env.api" -}}
{{ include "allama.env.common" . }}
{{ include "allama.env.temporal" . }}
{{ include "allama.env.blobStorage" . }}
{{ include "allama.env.postgres" . }}
{{ include "allama.env.redis" . }}
- name: ALLAMA__API_ROOT_PATH
  value: "/api"
- name: ALLAMA__API_URL
  value: {{ include "allama.internalApiUrl" . | quote }}
- name: ALLAMA__PUBLIC_APP_URL
  value: {{ include "allama.publicAppUrl" . | quote }}
- name: ALLAMA__PUBLIC_API_URL
  value: {{ include "allama.publicApiUrl" . | quote }}
{{- $publicS3Url := include "allama.publicS3Url" . }}
{{- if $publicS3Url }}
- name: ALLAMA__BLOB_STORAGE_PRESIGNED_URL_ENDPOINT
  value: {{ $publicS3Url | quote }}
{{- end }}
- name: ALLAMA__ALLOW_ORIGINS
  value: {{ .Values.allama.allowOrigins | quote }}
{{- /* Auth settings */}}
- name: ALLAMA__AUTH_TYPES
  value: {{ .Values.allama.auth.types | quote }}
- name: ALLAMA__AUTH_ALLOWED_DOMAINS
  value: {{ .Values.allama.auth.allowedDomains | quote }}
- name: ALLAMA__AUTH_MIN_PASSWORD_LENGTH
  value: "16"
- name: ALLAMA__AUTH_SUPERADMIN_EMAIL
  value: {{ .Values.allama.auth.superadminEmail | quote }}
{{- /* SAML settings */}}
{{- if .Values.allama.saml.enabled }}
- name: SAML_IDP_METADATA_URL
  value: {{ .Values.allama.saml.idpMetadataUrl | quote }}
- name: SAML_ALLOW_UNSOLICITED
  value: {{ .Values.allama.saml.allowUnsolicited | quote }}
- name: SAML_ACCEPTED_TIME_DIFF
  value: {{ .Values.allama.saml.acceptedTimeDiff | quote }}
- name: SAML_AUTHN_REQUESTS_SIGNED
  value: {{ .Values.allama.saml.authnRequestsSigned | quote }}
- name: SAML_SIGNED_ASSERTIONS
  value: {{ .Values.allama.saml.signedAssertions | quote }}
- name: SAML_SIGNED_RESPONSES
  value: {{ .Values.allama.saml.signedResponses | quote }}
- name: SAML_VERIFY_SSL_ENTITY
  value: {{ .Values.allama.saml.verifySslEntity | quote }}
- name: SAML_VERIFY_SSL_METADATA
  value: {{ .Values.allama.saml.verifySslMetadata | quote }}
- name: SAML_CA_CERTS
  value: {{ .Values.allama.saml.caCerts | quote }}
- name: SAML_METADATA_CERT
  value: {{ .Values.allama.saml.metadataCert | quote }}
{{- end }}
{{- /* Streaming */}}
- name: ALLAMA__UNIFIED_AGENT_STREAMING_ENABLED
  value: "true"
{{- end }}

{{/*
Worker service environment variables
Merges: common + temporal + postgres + redis + worker-specific
*/}}
{{- define "allama.env.worker" -}}
{{ include "allama.env.common" . }}
{{ include "allama.env.temporal" . }}
{{ include "allama.env.postgres" . }}
{{ include "allama.env.redis" . }}
- name: ALLAMA__API_ROOT_PATH
  value: "/api"
- name: ALLAMA__API_URL
  value: {{ include "allama.internalApiUrl" . | quote }}
- name: ALLAMA__PUBLIC_API_URL
  value: {{ include "allama.publicApiUrl" . | quote }}
{{- /* Context compression */}}
- name: ALLAMA__CONTEXT_COMPRESSION_ENABLED
  value: {{ .Values.worker.contextCompression.enabled | quote }}
- name: ALLAMA__CONTEXT_COMPRESSION_THRESHOLD_KB
  value: {{ .Values.worker.contextCompression.thresholdKb | quote }}
{{- /* Sentry */}}
{{- if .Values.allama.sentryDsn }}
- name: SENTRY_DSN
  value: {{ .Values.allama.sentryDsn | quote }}
{{- end }}
{{- end }}

{{/*
Executor service environment variables
Merges: common + temporal + postgres + redis + executor-specific
*/}}
{{- define "allama.env.executor" -}}
{{ include "allama.env.common" . }}
{{ include "allama.env.temporal" . }}
{{ include "allama.env.blobStorage" . }}
{{ include "allama.env.postgres" . }}
{{ include "allama.env.redis" . }}
- name: ALLAMA__API_URL
  value: {{ include "allama.internalApiUrl" . | quote }}
{{- /* Context compression */}}
- name: ALLAMA__CONTEXT_COMPRESSION_ENABLED
  value: {{ .Values.executor.contextCompression.enabled | quote }}
- name: ALLAMA__CONTEXT_COMPRESSION_THRESHOLD_KB
  value: {{ .Values.executor.contextCompression.thresholdKb | quote }}
{{- /* Sandbox settings */}}
- name: ALLAMA__DISABLE_NSJAIL
  value: {{ .Values.allama.sandbox.disableNsjail | quote }}
- name: ALLAMA__SANDBOX_NSJAIL_PATH
  value: "/usr/local/bin/nsjail"
- name: ALLAMA__SANDBOX_ROOTFS_PATH
  value: "/var/lib/allama/sandbox-rootfs"
- name: ALLAMA__SANDBOX_CACHE_DIR
  value: "/var/lib/allama/sandbox-cache"
{{- /* Executor settings */}}
- name: ALLAMA__EXECUTOR_BACKEND
  value: {{ .Values.executor.backend | quote }}
- name: ALLAMA__EXECUTOR_QUEUE
  value: {{ .Values.executor.queue | quote }}
- name: ALLAMA__EXECUTOR_WORKER_POOL_SIZE
  value: {{ .Values.executor.workerPoolSize | quote }}
{{- /* Secret masking */}}
- name: ALLAMA__UNSAFE_DISABLE_SM_MASKING
  value: "false"
{{- end }}

{{/*
UI service environment variables
*/}}
{{- define "allama.env.ui" -}}
- name: NODE_ENV
  value: "production"
- name: NEXT_PUBLIC_APP_ENV
  value: {{ .Values.allama.appEnv | quote }}
- name: NEXT_PUBLIC_APP_URL
  value: {{ include "allama.publicAppUrl" . | quote }}
- name: NEXT_PUBLIC_API_URL
  value: {{ include "allama.publicApiUrl" . | quote }}
- name: NEXT_PUBLIC_AUTH_TYPES
  value: {{ .Values.allama.auth.types | quote }}
- name: NEXT_SERVER_API_URL
  value: {{ include "allama.internalApiUrl" . | quote }}
{{- end }}

{{/*
=============================================================================
Secret Reference Helpers
=============================================================================
*/}}

{{/*
Helper to determine if a secret reference is an AWS Secrets Manager ARN
*/}}
{{- define "allama.isAwsSecret" -}}
{{- if and . (hasPrefix "arn:aws" .) }}true{{- end }}
{{- end }}

{{/*
Generate secret key reference for Kubernetes secrets
Usage: {{ include "allama.secretKeyRef" (dict "secretName" "my-secret" "key" "password") }}
*/}}
{{- define "allama.secretKeyRef" -}}
valueFrom:
  secretKeyRef:
    name: {{ .secretName }}
    key: {{ .key }}
{{- end }}

{{/*
=============================================================================
ESO-Aware Secret Name Resolution
=============================================================================
*/}}

{{/*
Get the effective core secrets name.
When ESO is enabled with coreSecrets, use the ESO target name.
Otherwise, require the manual existingSecret.
*/}}
{{- define "allama.secrets.coreName" -}}
{{- if and .Values.externalSecrets.enabled .Values.externalSecrets.coreSecrets.enabled .Values.externalSecrets.coreSecrets.secretArn }}
{{- .Values.externalSecrets.coreSecrets.targetSecretName }}
{{- else if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- fail "Either secrets.existingSecret or externalSecrets.coreSecrets (with secretArn) must be configured" }}
{{- end }}
{{- end }}

{{/*
Get the effective OAuth secrets name.
*/}}
{{- define "allama.secrets.oauthName" -}}
{{- if and .Values.externalSecrets.enabled .Values.externalSecrets.oauthSecrets.enabled .Values.externalSecrets.oauthSecrets.secretArn }}
{{- .Values.externalSecrets.oauthSecrets.targetSecretName }}
{{- else }}
{{- .Values.secrets.oauthSecret }}
{{- end }}
{{- end }}

{{/*
Get the effective PostgreSQL secrets name for external Postgres.
ESO-managed secret takes precedence over existingSecret.
*/}}
{{- define "allama.secrets.postgresName" -}}
{{- if and .Values.externalSecrets.enabled .Values.externalSecrets.postgres.enabled .Values.externalSecrets.postgres.secretArn }}
{{- .Values.externalSecrets.postgres.targetSecretName }}
{{- else if .Values.externalPostgres.auth.existingSecret }}
{{- .Values.externalPostgres.auth.existingSecret }}
{{- end }}
{{- end }}

{{/*
Get the effective Redis secrets name for external Redis.
*/}}
{{- define "allama.secrets.redisName" -}}
{{- if and .Values.externalSecrets.enabled .Values.externalSecrets.redis.enabled .Values.externalSecrets.redis.secretArn }}
{{- .Values.externalSecrets.redis.targetSecretName }}
{{- else if .Values.externalRedis.auth.existingSecret }}
{{- .Values.externalRedis.auth.existingSecret }}
{{- end }}
{{- end }}

{{/*
Get the effective Temporal secrets name for external Temporal.
*/}}
{{- define "allama.secrets.temporalName" -}}
{{- if and .Values.externalSecrets.enabled .Values.externalSecrets.temporal.enabled .Values.externalSecrets.temporal.secretArn }}
{{- .Values.externalSecrets.temporal.targetSecretName }}
{{- else if .Values.externalTemporal.auth.existingSecret }}
{{- .Values.externalTemporal.auth.existingSecret }}
{{- end }}
{{- end }}

{{/*
=============================================================================
Validation Helpers
=============================================================================
*/}}

{{/*
Validate required secrets - accepts either manual secret or ESO-managed secret
*/}}
{{- define "allama.validateRequiredSecrets" -}}
{{- $hasManualSecret := .Values.secrets.existingSecret -}}
{{- $hasEsoSecret := and .Values.externalSecrets.enabled .Values.externalSecrets.coreSecrets.enabled .Values.externalSecrets.coreSecrets.secretArn -}}
{{- if not (or $hasManualSecret $hasEsoSecret) -}}
{{- fail "Core secrets required: set secrets.existingSecret OR enable externalSecrets with coreSecrets.secretArn" -}}
{{- end -}}
{{- end -}}

{{/*
Validate auth config on first install
*/}}
{{- define "allama.validateAuthConfig" -}}
{{- if .Release.IsInstall -}}
{{- if not .Values.allama.auth.superadminEmail -}}
{{- fail "allama.auth.superadminEmail is required on first install" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate infrastructure dependencies
*/}}
{{- define "allama.validateInfrastructure" -}}
{{- if and (not .Values.postgres.enabled) (not .Values.externalPostgres.enabled) -}}
{{- fail "Either postgres.enabled or externalPostgres.enabled must be true" -}}
{{- end -}}
{{- if and (not .Values.redis.enabled) (not .Values.externalRedis.enabled) -}}
{{- fail "Either redis.enabled or externalRedis.enabled must be true" -}}
{{- end -}}
{{- if and (not .Values.temporal.enabled) (not .Values.externalTemporal.enabled) -}}
{{- fail "Either temporal.enabled or externalTemporal.enabled must be true" -}}
{{- end -}}
{{- end -}}

{{/*
=============================================================================
Secret Environment Variable Helpers
=============================================================================
*/}}

{{/*
Secret environment variables (shared by api, worker, executor)
Uses ESO-aware secret name resolution.
*/}}
{{- define "allama.env.secrets" -}}
{{- $secretName := include "allama.secrets.coreName" . }}
- name: ALLAMA__DB_ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: dbEncryptionKey
- name: ALLAMA__SERVICE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: serviceKey
- name: ALLAMA__SIGNING_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: signingSecret
{{- end -}}

{{/*
API-specific secret env vars (OAuth, user auth)
Uses ESO-aware secret name resolution.
*/}}
{{- define "allama.env.secrets.api" -}}
{{- $coreSecretName := include "allama.secrets.coreName" . }}
{{- $oauthSecretName := include "allama.secrets.oauthName" . }}
{{ include "allama.env.secrets" . }}
- name: USER_AUTH_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ $coreSecretName }}
      key: userAuthSecret
{{- if $oauthSecretName }}
- name: OAUTH_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ $oauthSecretName }}
      key: oauthClientId
      optional: true
- name: OAUTH_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ $oauthSecretName }}
      key: oauthClientSecret
      optional: true
{{- end }}
{{- end -}}

{{/*
UI-specific secret env vars
Uses ESO-aware secret name resolution.
*/}}
{{- define "allama.env.secrets.ui" -}}
{{- $secretName := include "allama.secrets.coreName" . }}
- name: ALLAMA__SERVICE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: serviceKey
{{- end -}}
