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
     environment:
       SETTING_EXTERNAL_HOST: zulip.example.com
       SETTING_ZULIP_ADMINISTRATOR: "admin@example.com"
       SECRETS_secret_key: "replace-with-a-secure-secret-key"
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

## Local development with Minikube

[Minikube](https://minikube.sigs.k8s.io/docs/) provides a local
single-node Kubernetes cluster for development. Zulip requires TLS
(or at least an Ingress) to function correctly, so a few extra setup
steps are needed.

1. Enable the Ingress addon:

   ```bash
   minikube addons enable ingress
   ```

1. Install [cert-manager](https://cert-manager.io/docs/installation/)
   to handle TLS certificates:

   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
   ```

   Wait for the cert-manager pods to be ready:

   ```bash
   kubectl -n cert-manager wait --for=condition=Ready pods --all --timeout=120s
   ```

1. Create a `ClusterIssuer` that issues self-signed certificates:

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: selfsigned
   spec:
     selfSigned: {}
   EOF
   ```

1. Point a hostname at your Minikube IP. Add a line to `/etc/hosts`:

   ```text
   <minikube-ip>  zulip.local
   ```

   You can get the IP with `minikube ip`.

1. Follow the [installation steps above](#installation), setting
   `SETTING_EXTERNAL_HOST` to `zulip.local` and enabling the Ingress
   with the self-signed issuer:

   ```yaml
   zulip:
     environment:
       SETTING_EXTERNAL_HOST: zulip.local
   ingress:
     enabled: true
     className: nginx
     annotations:
       cert-manager.io/cluster-issuer: selfsigned
     hosts:
       - host: zulip.local
         paths:
           - path: /
     tls:
       - secretName: zulip-tls
         hosts:
           - zulip.local
   ```

   Then open `https://zulip.local` in your browser (accepting the
   self-signed certificate warning).

## See also

- {doc}`helm-commands`
- {doc}`/reference/environment-vars`
