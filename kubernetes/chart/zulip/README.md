# Zulip

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 7.0-0](https://img.shields.io/badge/AppVersion-7.0--0-informational?style=flat-square)

[Zulip](https://zulip.com/) is an open source threaded team chat that helps teams stay productive and focused.

Helm chart based on https://github.com/zulip/docker-zulip

## Installation

Copy `values-local.yaml.example`, modify it as instructed in the comments, then
install with the following commands:

```
helm dependency update                      # Get helm dependency charts
helm install -f ./values-local.yaml zulip . # Install Zulip
```

This will show a message on how to reach your Zulip installation and how to
create your first realm. Wait for all your pods to be ready before you continue.
You can run `kubectl get pods` to their current state. Once all pods are ready,
you can run the commands to create a Realm, and you can reach Zulip following
the instructions as well.

### Installing on Minikube

You need to do a few things to make
[minikube](https://minikube.sigs.k8s.io/docs/) serve Zulip with a TLS
certificate. Without it, Zulip will not work.

If you haven't already, you need to set up `cert-manager` inside your minikube.

First, enable the "ingress" minikube addon ([more info available
here](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/#enable-the-ingress-controller))

```
minikube addons enable ingress
```

Second, [install cert-manager into your minikube
cluster](https://cert-manager.io/docs/installation/#default-static-install):

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
```

Now you'll need to add an issuer that issues self-signed certificates. Copy this
into a file, `self-signed-issuer.yaml`

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
  namespace: cert-manager
spec:
  selfSigned: {}
```

Now apply the issuer: `kubectl apply -f self-signed-issuer.yaml`

We'll host Zulip on `zulip.local`. Add that to your `/etc/hosts` file and
point it to the IP address you get with the command `minikube ip`.

Now you're ready to follow [the installation instructions above](#installation).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment. Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| fullnameOverride | string | `""` | Fully override common.names.fullname template. |
| image.pullPolicy | string | `"IfNotPresent"` | Pull policy for Zulip docker image. Ref: https://kubernetes.io/docs/user-guide/images/#pre-pulling-images |
| image.repository | string | `"zulip/docker-zulip"` | Defaults to hub.docker.com/zulip/docker-zulip, but can be overwritten with a full HTTPS address. |
| image.tag | string | `"7.0-0"` | Zulip image tag (immutable tags are recommended) |
| imagePullSecrets | list | `[]` | Global Docker registry secret names as an array. |
| ingress.annotations | object | `{}` | Can be used to add custom Ingress annotations. |
| ingress.enabled | bool | `false` | Enable this to use an Ingress to reach the Zulip service. |
| ingress.hosts[0] | object | `{"host":"zulip.example.com","paths":[{"path":"/"}]}` | Host for the Ingress. Should be the same as `zulip.environment.SETTING_EXTERNAL_HOST`. |
| ingress.hosts[0].paths | list | `[{"path":"/"}]` | Serves Zulip root of the chosen host domain. |
| ingress.tls | list | `[]` | Set a specific secret to read the TLS certificate from. If you use cert-manager, it will save the TLS secret here. If you do not, you need to manually create a secret with your TLS certificate. |
| livenessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Liveness probe values. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes |
| memcached | object | `{"memcachedUsername":"zulip@localhost"}` | Memcached settings, see [Requirements](#Requirements). |
| nameOverride | string | `""` | Partially override common.names.fullname template (will maintain the release name). |
| nodeSelector | object | `{}` | Optionally add a nodeSelector to the Zulip pod, so it runs on a specific node. Ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| podAnnotations | object | `{}` | Custom annotations to add to the Zulip Pod. |
| podLabels | object | `{}` | Custom labels to add to the Zulip Pod. |
| podSecurityContext | object | `{}` | Can be used to override the default PodSecurityContext (fsGroup, runAsUser and runAsGroup) of the Zulip _Pod_. |
| postSetup.scripts | object | `{}` | The Docker entrypoint script runs commands from `/data/post-setup.d` after the Zulip application's Setup phase has completed. Scripts can be added here as `script_filename: <script contents>` and they will be mounted in `/data/post-setup.d/script_filename`. |
| postgresql | object | `{"auth":{"database":"zulip","username":"zulip"},"image":{"repository":"zulip/zulip-postgresql","tag":14},"primary":{"containerSecurityContext":{"runAsUser":0}}}` | PostgreSQL settings, see [Requirements](#Requirements). |
| rabbitmq | object | `{"auth":{"username":"zulip"},"persistence":{"enabled":false}}` | Rabbitmq settings, see [Requirements](#Requirements). |
| redis | object | `{"architecture":"standalone","master":{"persistence":{"enabled":false}}}` | Redis settings, see [Requirements](#Requirements). |
| resources | object | `{}` |  |
| securityContext | object | `{}` | Can be used to override the default SecurityContext of the Zulip _container_. |
| service | object | `{"port":80,"type":"ClusterIP"}` | Service type and port for the Kubernetes service that connects to Zulip. Default: ClusterIP, needs an Ingress to be used. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| startupProbe | object | `{"enabled":true,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Startup probe values. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes |
| statefulSetAnnotations | object | `{}` | Custom annotations to add to the Zulip StatefulSet. |
| statefulSetLabels | object | `{}` | Custom labels to add to the Zulip StatefulSet. |
| tolerations | list | `[]` | Tolerations for pod assignment. Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| zulip.environment.DISABLE_HTTPS | bool | `true` | Disables HTTPS if set to "true". HTTPS and certificates are managed by the Kubernetes cluster, so by default it's disabled inside the container |
| zulip.environment.SECRETS_email_password | string | `"123456789"` | SMTP email password. |
| zulip.environment.SETTING_EMAIL_HOST | string | `""` |  |
| zulip.environment.SETTING_EMAIL_HOST_USER | string | `"noreply@example.com"` |  |
| zulip.environment.SETTING_EMAIL_PORT | string | `"587"` |  |
| zulip.environment.SETTING_EMAIL_USE_SSL | string | `"False"` |  |
| zulip.environment.SETTING_EMAIL_USE_TLS | string | `"True"` |  |
| zulip.environment.SETTING_EXTERNAL_HOST | string | `"zulip.example.com"` | Domain Zulip is hosted on. |
| zulip.environment.SETTING_ZULIP_ADMINISTRATOR | string | `"admin@example.com"` |  |
| zulip.environment.SSL_CERTIFICATE_GENERATION | string | `"self-signed"` | Set SSL certificate generation to self-signed because Kubernetes manages the client-facing SSL certs. |
| zulip.environment.ZULIP_AUTH_BACKENDS | string | `"EmailAuthBackend"` |  |
| zulip.persistence | object | `{"accessMode":"ReadWriteOnce","enabled":true,"size":"10Gi"}` | If `persistence.existingClaim` is not set, a PVC is generated with these specifications. |

## About this helm chart

This helm chart sets up a StatefulSet that runs a Zulip pod, that in turn runs
the [docker-zulip](https://hub.docker.com/r/zulip/docker-zulip/) Dockerized
Zulip version. Configuration of Zulip happens through environment variables that
are defined in the `values.yaml` under `zulip.environment`. These environment
variables are forwarded to the Docker container, you can read more about
configuring Zulip through environment variables
[here](https://github.com/zulip/docker-zulip/#configuration).

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

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | memcached | 6.0.16 |
| https://charts.bitnami.com/bitnami | postgresql | 11.1.22 |
| https://charts.bitnami.com/bitnami | rabbitmq | 8.32.0 |
| https://charts.bitnami.com/bitnami | redis | 16.8.7 |
