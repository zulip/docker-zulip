# Ports exposed by the Docker image

The `ghcr.io/zulip/zulip-server` image exposes three TCP ports. Each one
serves a distinct purpose, has its own configuration story, and is
published differently by the Docker Compose deployment and the Helm
chart.

## Summary

| Port | Name    | Purpose                                                                                                | Compose default        | Helm default                          |
| ---- | ------- | ------------------------------------------------------------------------------------------------------ | ---------------------- | ------------------------------------- |
| 25   | `smtp`  | Inbound SMTP, used by Zulip's [email gateway](inv:zulip:*#production/email-gateway) for incoming email | Published on host :25  | Not exposed by the `Service`          |
| 80   | `http`  | Plaintext HTTP traffic; the default for deployments behind a TLS-terminating proxy                     | Published on host :80  | Selected when `CERTIFICATES` is unset |
| 443  | `https` | TLS-terminated HTTPS, used when the container manages its own certificate                              | Published on host :443 | Selected when `CERTIFICATES` is set   |

## Port 80 (HTTP) and port 443 (HTTPS)

Zulip serves end-user web traffic from exactly one of these ports at a
time, never both. The choice is driven by the {ref}`certificates`
environment variable:

- If `CERTIFICATES` is unset (the default), the container serves
  unencrypted HTTP on port 80 and expects to be placed behind a
  TLS-terminating reverse proxy or load balancer.
- If `CERTIFICATES` is set to `self-signed`, `certbot`, or `manual`,
  the container terminates TLS itself and serves HTTPS on port 443.

The Compose configuration publishes both ports on the host so that
either deployment mode works without further changes. The Helm chart
points its `Service` at the port chosen by `CERTIFICATES`; the unused
port is reachable inside the pod but not via the `Service`.

For configuration details, see {doc}`/how-to/compose-ssl` and
{doc}`/how-to/helm-ssl`.

## Port 25 (SMTP)

Port 25 receives inbound email for Zulip's
[incoming email gateway](inv:zulip:*#production/email-gateway), which
turns email replies into Zulip messages. It is unrelated to
**outgoing** email (which Zulip sends via the
[`SETTING_EMAIL_HOST` settings](inv:zulip:*#production/email)).

The Compose configuration publishes port 25 on the host; for setup
instructions, see {doc}`/how-to/compose-incoming-email`.

The Helm chart's default `Service` exposes only port 80, so port 25 is
not reachable from outside the pod. Operators who want to use the
incoming email gateway with Helm need to add a second `Service` (for
example, of type `LoadBalancer`) targeting the `smtp` named port on
the StatefulSet pod.

## See also

- {doc}`environment-vars`
- {doc}`/how-to/compose-ssl`
- {doc}`/how-to/compose-ports`
- {doc}`/how-to/compose-incoming-email`
- {doc}`/how-to/helm-ssl`
