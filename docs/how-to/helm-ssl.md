# Helm: Configuring TLS

In a Kubernetes deployment, TLS is typically terminated at the Ingress controller
rather than inside the Zulip container itself. By default, the Helm chart serves
unencrypted HTTP on port 80 and expects a TLS-terminating Ingress or load
balancer in front of it.

## Using an Ingress with cert-manager

The recommended production setup uses an [Ingress
controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
(such as [Traefik](https://doc.traefik.io/traefik/)) combined with
[cert-manager](https://cert-manager.io/) for automatic TLS certificate
provisioning from Let's Encrypt.

1. Install an Ingress controller and cert-manager in your cluster. Refer to
   their respective documentation for installation instructions.

1. Create a `ClusterIssuer` for Let's Encrypt (if you don't already have one):

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-prod
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: admin@example.com
       privateKeySecretRef:
         name: letsencrypt-prod
       solvers:
         - http01:
             ingress:
               ingressClassName: traefik
   ```

1. Enable the Ingress in your values file:

   ```yaml
   ingress:
     enabled: true
     className: traefik
     annotations:
       cert-manager.io/cluster-issuer: letsencrypt-prod
     hosts:
       - host: zulip.example.com
         paths:
           - path: /
     tls:
       - secretName: zulip-tls
         hosts:
           - zulip.example.com
   ```

1. Ensure `SETTING_EXTERNAL_HOST` matches the Ingress host:

   ```yaml
   zulip:
     environment:
       SETTING_EXTERNAL_HOST: zulip.example.com
   ```

1. Install or upgrade the chart:

   ```bash
   helm upgrade --install zulip . -f values-local.yaml
   ```

   cert-manager will automatically provision a TLS certificate and store it in
   the `zulip-tls` Secret.

## Using a pre-existing TLS secret

If you manage TLS certificates outside of cert-manager, you can reference an
existing Kubernetes TLS Secret:

1. Create the Secret with your certificate and key:

   ```bash
   kubectl create secret tls zulip-tls \
       --cert=path/to/tls.crt \
       --key=path/to/tls.key
   ```

1. Reference the secret in your Ingress configuration:

   ```yaml
   ingress:
     enabled: true
     className: traefik
     hosts:
       - host: zulip.example.com
         paths:
           - path: /
     tls:
       - secretName: zulip-tls
         hosts:
           - zulip.example.com
   ```

## Using a cloud load balancer

If you prefer to terminate TLS at a cloud load balancer (e.g. AWS NLB, GCP
Load Balancer) instead of using an Ingress, you can configure the Service as
type `LoadBalancer`:

```yaml
service:
  type: LoadBalancer
  port: 443
  annotations:
    # AWS NLB example:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:...
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
```

Consult your cloud provider's documentation for the appropriate annotations.

## Container-level TLS

While not recommended for Kubernetes deployments (since TLS is normally handled
by the Ingress or load balancer), the chart also supports TLS termination inside
the Zulip container itself by setting `CERTIFICATES`:

```yaml
zulip:
  environment:
    CERTIFICATES: self-signed
```

When `CERTIFICATES` is set to a non-empty value, the Service's `targetPort`
switches from `http` (port 80) to `https` (port 443) automatically.

## See also

- [Kubernetes Ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [cert-manager documentation](https://cert-manager.io/docs/)
- {doc}`helm-settings`
- {doc}`helm-getting-started`
