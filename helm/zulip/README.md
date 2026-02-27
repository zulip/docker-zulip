# Zulip

![Version: 1.11.56](https://img.shields.io/badge/Version-1.11.56-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 11.5-2](https://img.shields.io/badge/AppVersion-11.5--2-informational?style=flat-square)

[Zulip](https://zulip.com/) is an open source threaded team chat that helps teams stay productive and focused.

Helm chart based on https://github.com/zulip/docker-zulip

> **Full documentation:**
> https://zulip.readthedocs.io/projects/docker/en/latest/how-to/helm-index.html

## Quick start

```bash
helm dependency build
helm install zulip . -f values-local.yaml
```

See the
[getting-started guide](https://zulip.readthedocs.io/projects/docker/en/latest/how-to/helm-getting-started.html)
for detailed installation instructions, including required settings
and creating your first organization.

## Values

| Key                                                                | Type   | Default                        | Description |
| ------------------------------------------------------------------ | ------ | ------------------------------ | ----------- |
| affinity                                                           | object | `{}`                           |             |
| externalMemcached.host                                             | string | `""`                           |             |
| externalMemcached.password                                         | string | `""`                           |             |
| externalMemcached.port                                             | int    | `11211`                        |             |
| externalMemcached.user                                             | string | `""`                           |             |
| externalPostgresql.database                                        | string | `"zulip"`                      |             |
| externalPostgresql.host                                            | string | `""`                           |             |
| externalPostgresql.password                                        | string | `""`                           |             |
| externalPostgresql.port                                            | int    | `5432`                         |             |
| externalPostgresql.sslmode                                         | string | `""`                           |             |
| externalPostgresql.user                                            | string | `"zulip"`                      |             |
| externalRabbitmq.host                                              | string | `""`                           |             |
| externalRabbitmq.password                                          | string | `""`                           |             |
| externalRabbitmq.port                                              | int    | `5672`                         |             |
| externalRabbitmq.user                                              | string | `"zulip"`                      |             |
| externalRedis.host                                                 | string | `""`                           |             |
| externalRedis.password                                             | string | `""`                           |             |
| externalRedis.port                                                 | int    | `6379`                         |             |
| extraObjects                                                       | list   | `[]`                           |             |
| fullnameOverride                                                   | string | `""`                           |             |
| global.security.allowInsecureImages                                | bool   | `true`                         |             |
| image.pullPolicy                                                   | string | `"IfNotPresent"`               |             |
| image.repository                                                   | string | `"ghcr.io/zulip/zulip-server"` |             |
| image.tag                                                          | string | `"11.5-2"`                     |             |
| imagePullSecrets                                                   | list   | `[]`                           |             |
| ingress.annotations                                                | object | `{}`                           |             |
| ingress.className                                                  | string | `nil`                          |             |
| ingress.enabled                                                    | bool   | `false`                        |             |
| ingress.hosts[0].host                                              | string | `"zulip.example.com"`          |             |
| ingress.hosts[0].paths[0].path                                     | string | `"/"`                          |             |
| ingress.tls                                                        | list   | `[]`                           |             |
| livenessProbe.enabled                                              | bool   | `true`                         |             |
| livenessProbe.failureThreshold                                     | int    | `3`                            |             |
| livenessProbe.initialDelaySeconds                                  | int    | `10`                           |             |
| livenessProbe.periodSeconds                                        | int    | `10`                           |             |
| livenessProbe.successThreshold                                     | int    | `1`                            |             |
| livenessProbe.timeoutSeconds                                       | int    | `5`                            |             |
| memcached.enabled                                                  | bool   | `true`                         |             |
| memcached.image.repository                                         | string | `"bitnamilegacy/memcached"`    |             |
| memcached.image.tag                                                | string | `"latest"`                     |             |
| memcached.memcachedUsername                                        | string | `"zulip@localhost"`            |             |
| nameOverride                                                       | string | `""`                           |             |
| nodeSelector                                                       | object | `{}`                           |             |
| podAnnotations                                                     | object | `{}`                           |             |
| podLabels                                                          | object | `{}`                           |             |
| podSecurityContext                                                 | object | `{}`                           |             |
| postSetup.scripts                                                  | object | `{}`                           |             |
| postgresql.auth.database                                           | string | `"zulip"`                      |             |
| postgresql.auth.username                                           | string | `"zulip"`                      |             |
| postgresql.enabled                                                 | bool   | `true`                         |             |
| postgresql.image.repository                                        | string | `"zulip/zulip-postgresql"`     |             |
| postgresql.image.tag                                               | int    | `14`                           |             |
| postgresql.primary.containerSecurityContext.readOnlyRootFilesystem | bool   | `false`                        |             |
| postgresql.primary.containerSecurityContext.runAsGroup             | int    | `70`                           |             |
| postgresql.primary.containerSecurityContext.runAsUser              | int    | `70`                           |             |
| rabbitmq.auth.username                                             | string | `"zulip"`                      |             |
| rabbitmq.enabled                                                   | bool   | `true`                         |             |
| rabbitmq.image.repository                                          | string | `"bitnamilegacy/rabbitmq"`     |             |
| rabbitmq.image.tag                                                 | string | `"4.1.3"`                      |             |
| rabbitmq.persistence.enabled                                       | bool   | `false`                        |             |
| redis.architecture                                                 | string | `"standalone"`                 |             |
| redis.enabled                                                      | bool   | `true`                         |             |
| redis.image.repository                                             | string | `"bitnamilegacy/redis"`        |             |
| redis.image.tag                                                    | string | `"latest"`                     |             |
| redis.master.persistence.enabled                                   | bool   | `false`                        |             |
| resources                                                          | object | `{}`                           |             |
| securityContext                                                    | object | `{}`                           |             |
| service.annotations                                                | object | `{}`                           |             |
| service.port                                                       | int    | `80`                           |             |
| service.type                                                       | string | `"ClusterIP"`                  |             |
| serviceAccount.annotations                                         | object | `{}`                           |             |
| serviceAccount.create                                              | bool   | `true`                         |             |
| serviceAccount.name                                                | string | `""`                           |             |
| sidecars                                                           | list   | `[]`                           |             |
| startupProbe.enabled                                               | bool   | `true`                         |             |
| startupProbe.failureThreshold                                      | int    | `30`                           |             |
| startupProbe.initialDelaySeconds                                   | int    | `10`                           |             |
| startupProbe.periodSeconds                                         | int    | `10`                           |             |
| startupProbe.successThreshold                                      | int    | `1`                            |             |
| startupProbe.timeoutSeconds                                        | int    | `5`                            |             |
| statefulSetAnnotations                                             | object | `{}`                           |             |
| statefulSetLabels                                                  | object | `{}`                           |             |
| tolerations                                                        | list   | `[]`                           |             |
| zulip.environment.TRUST_GATEWAY_IP                                 | bool   | `true`                         |             |
| zulip.persistence.accessMode                                       | string | `"ReadWriteOnce"`              |             |
| zulip.persistence.enabled                                          | bool   | `true`                         |             |
| zulip.persistence.size                                             | string | `"10Gi"`                       |             |
| zulip.persistence.storageClass                                     | string | `nil`                          |             |

Environment values can be plain scalars or
[`valueFrom` references](https://zulip.readthedocs.io/projects/docker/en/latest/how-to/helm-settings.html#referencing-kubernetes-secrets-with-valuefrom)
to Kubernetes Secrets; see the
[settings guide](https://zulip.readthedocs.io/projects/docker/en/latest/how-to/helm-settings.html)
for details.

### Dependencies

The chart uses Memcached, RabbitMQ and Redis helm charts defined in
the Bitnami Helm repository. Most of these are configured following their
default settings, but you can check
https://github.com/bitnami/charts/tree/master/bitnami/ for more configuration
options of the subcharts.

For PostgreSQL the chart also uses the Bitnami chart to install it on the
Kubernetes cluster. However, in this case we use Zulip's
[zulip-postgresql](https://hub.docker.com/r/zulip/zulip-postgresql) docker
image, because it contains the Postgresql plugins that are needed to run Zulip.

## Requirements

| Repository                               | Name       | Version |
| ---------------------------------------- | ---------- | ------- |
| oci://registry-1.docker.io/bitnamicharts | memcached  | 8.1.5   |
| oci://registry-1.docker.io/bitnamicharts | postgresql | 18.1.8  |
| oci://registry-1.docker.io/bitnamicharts | rabbitmq   | 16.0.14 |
| oci://registry-1.docker.io/bitnamicharts | redis      | 23.2.12 |
