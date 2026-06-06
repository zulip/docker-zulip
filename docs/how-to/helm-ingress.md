# Helm: Using your own Ingress solution

The Helm chart does not require any particular Ingress solution. The
Ingress resource it can create (`ingress.enabled`, disabled by
default) is a convenience, not a requirement; any Ingress controller,
Gateway API implementation, service mesh, or cloud load balancer
works, as long as it fulfills the small contract below.

## What Zulip needs from the proxy in front of it

Whatever routes traffic to Zulip must:

1. **Route HTTP to the chart's Service.** By default, the Service
   listens on port 80 and the Zulip pod serves unencrypted HTTP; see
   {doc}`helm-ssl`.

1. **Terminate TLS, and set `X-Forwarded-Proto`.** Zulip requires
   HTTPS in production. The proxy must set the `X-Forwarded-Proto`
   header to `https`, overriding any client-supplied value; Django
   uses it for CSRF checks and secure cookies.

1. **Set `X-Forwarded-For`, and be listed in `LOADBALANCER_IPS`.**
   Zulip only trusts `X-Forwarded-*` headers from source addresses
   listed in `LOADBALANCER_IPS`, so that clients cannot spoof their
   IP addresses to evade rate limiting and audit logging. See
   {doc}`helm-proxy-trust`.

1. **Pass the client's `Host:` header through unchanged**, and route
   the hostname in `SETTING_EXTERNAL_HOST` (and any realm subdomains
   of it) to the Service.

1. **Permit long-lived requests.** Zulip delivers real-time events
   over HTTP long-polling, so idle/read timeouts on the route must be
   significantly longer than 60 seconds (`proxy_read_timeout` in
   nginx terms), and response buffering should be disabled if your
   proxy buffers by default.

These are the same requirements as for any reverse proxy in front of
a standalone Zulip server; see
{doc}`zulip:production/reverse-proxies`.

## What stays Zulip configuration

Two settings remain with Zulip no matter which Ingress solution you
choose, because they are application configuration, not proxy
configuration:

- `SETTING_EXTERNAL_HOST` is the canonical hostname users reach the
  server at. Zulip uses it to build absolute URLs in contexts where
  there is no request to derive a hostname from -- invitation and
  notification emails, and API and mobile-app server URLs -- and to
  validate the `Host:` header of incoming requests (Django's
  `ALLOWED_HOSTS`), which protects against Host-header attacks such
  as password-reset link poisoning. It cannot safely be derived from
  the request.

- `LOADBALANCER_IPS` tells Zulip which source addresses are your
  proxy layer, and hence when to believe `X-Forwarded-*` headers.

Both are statements of fact about the network the administrator
built, which Zulip cannot discover on its own; beyond them, DNS, TLS,
routing, and traffic policy are entirely up to your Ingress layer.

## See also

- {doc}`helm-ssl`
- {doc}`helm-proxy-trust`
- {doc}`helm-getting-started`
- {doc}`zulip:production/reverse-proxies`
