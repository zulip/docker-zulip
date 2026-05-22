# Helm: Configuring `LOADBALANCER_IPS`

Zulip requires that the IP addresses of any reverse proxies in front
of it be listed in {ref}`loadbalancer-ips`. Zulip uses this list to
decide whose `X-Forwarded-For` and `X-Forwarded-Proto` headers to
trust; requests carrying those headers from a source IP that is not
in the list are rejected with a "configure your reverse proxy" error
page.

In a Kubernetes deployment, the reverse proxy in front of Zulip is
typically the Ingress controller. The Helm chart leaves
`LOADBALANCER_IPS` unset by default; you must set it to your Ingress
controller's pod IP, Service IP, or CIDR before user traffic will be
served.

## If you're seeing the "configure your reverse proxy" error page

Zulip's error page tells you to add the request's source IP to
`LOADBALANCER_IPS`. In a Helm install, that means setting
`zulip.environment.LOADBALANCER_IPS` in your values file:

```yaml
zulip:
  environment:
    LOADBALANCER_IPS: 10.244.0.0/16
```

Then upgrade the release:

```bash
helm upgrade --install zulip oci://ghcr.io/zulip/helm-charts/zulip \
    -f values-local.yaml
```

The value to use is whatever IP Zulip's error page names as the
source of the rejected request; consult your Ingress controller's
documentation if you need a more stable CIDR than a single ephemeral
pod IP.

## Upgrading from chart 1.x

Chart 1.x defaulted `TRUST_GATEWAY_IP: true`, which trusted the pod's
default gateway as the proxy IP. That heuristic was unreliable across
CNIs (e.g. on Calico the gateway is the link-local `169.254.1.1`,
not the actual source of incoming traffic), so the default was
removed in chart 2.0. The env var itself is still available as
`zulip.environment.TRUST_GATEWAY_IP: true` for operators who want to
opt back in, but {ref}`loadbalancer-ips` is the recommended approach.

## See also

- {ref}`loadbalancer-ips`
- {ref}`trust-gateway-ip`
- {doc}`zulip:production/reverse-proxies`
- {doc}`helm-ssl`
- {doc}`helm-settings`
