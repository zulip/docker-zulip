# Helm: Getting started

## Prerequisites

- A running Kubernetes cluster (1.24+)
- [Helm](https://helm.sh/docs/intro/install/) 3.x
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured to access your
  cluster

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/zulip/docker-zulip.git
   cd docker-zulip/helm/zulip
   ```

1. Download the chart's dependency subcharts:

   ```bash
   helm dependency build
   ```

1. Create a `values-local.yaml` file with your deployment settings. At minimum,
   you must configure:

   ```yaml
   zulip:
     password: "replace-with-a-secure-secret-key"
     environment:
       SETTING_EXTERNAL_HOST: zulip.example.com
       SETTING_ZULIP_ADMINISTRATOR: "admin@example.com"
   ```

   You should also set passwords for the dependency services:

   ```yaml
   memcached:
     memcachedPassword: "replace-with-secure-password"
   rabbitmq:
     auth:
       password: "replace-with-secure-password"
       erlangCookie: "replace-with-secure-cookie"
   redis:
     auth:
       password: "replace-with-secure-password"
   postgresql:
     auth:
       postgresqlPassword: "replace-with-secure-password"
       password: "replace-with-secure-password"
   ```

   See {doc}`helm-settings` for more configuration options.

1. Install the chart:

   ```bash
   helm install zulip . -f values-local.yaml
   ```

   Zulip takes several minutes to start up on first boot. You can watch the pod
   status with:

   ```bash
   kubectl get pods -w
   ```

1. Once the pod is ready, generate a link to create your first organization:

   ```bash
   kubectl exec zulip-0 -c zulip -- \
       runuser -u zulip -- \
       /home/zulip/deployments/current/manage.py \
       generate_realm_creation_link
   ```

1. If you have configured an {doc}`Ingress <helm-ssl>`, open the link in a
   browser. Otherwise, you can use `kubectl port-forward` to access the server
   locally:

   ```bash
   kubectl port-forward svc/zulip 8080:80
   ```

   Then visit `http://localhost:8080` in your browser.

## Next steps

- {doc}`helm-settings` to configure Zulip's behavior.
- {doc}`helm-ssl` to set up TLS with an Ingress controller.
- Learn how to [get your organization
  started](https://zulip.com/help/moving-to-zulip) using Zulip at its best.

## See also

- {doc}`helm-commands`
- {doc}`/reference/environment-vars`
