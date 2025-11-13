# Compose: Configuring TLS

Zulip requires that all content be served encrypted using SSL/TLS, over
HTTPS. By default, the Zulip Docker container serves unencrypted content on port
80, and expects to be placed behind a proxy; however, there are a number of
other deployment options to help get up and running without configuring such a
proxy.

## Using a self-signed certificates

Zulip's Docker deployment supports generating and serving HTTPS traffic with
long-lived (10-year) self-signed certificates. These are generally only useful
for local development and testing; browsers will require that users click
through large warning messages, and Zulip Desktop requires additional
configuration to connect. See Zulip's documentation on [using a custom
certificate](https://zulip.com/help/custom-certificates).

1. Set, in your `compose.override.yaml`:

   ```yaml
   services:
     zulip:
       environment:
         CERTIFICATES: self-signed
   ```

1. Restart your Zulip Docker deploy:

   ```bash
   docker compose up zulip
   ```

## Using `certbot` to acquire Let's Encrypt certificates

[Let's Encrypt](https://letsencrypt.org/) is a free, completely
automated CA launched in 2016 to help make HTTPS routine for the
entire Web. Zulip offers a simple automation for
[Certbot](https://certbot.eff.org/), a Let's Encrypt client, to get
SSL certificates from Let's Encrypt and renew them automatically.

We recommend most Zulip servers use Let's Encrypt certificates. However, you
will need to use something else if your server is not publicly accessible on the
Internet, with a publicly-accessible hostname.

```{admonition} Let's Encrypt Terms of Service
Enabling this configuration will create an account with Let's Encrypt, using
Zulip's server administrator email address, and will accept [their Terms of
Service](https://letsencrypt.org/repository/#let-s-encrypt-subscriber-agreement).
```

1. Set, in your `compose.override.yaml`:

   ```yaml
   services:
     zulip:
       environment:
         CERTIFICATES: certbot
   ```

1. Restart your Zulip Docker deploy:

   ```bash
   docker compose up zulip
   ```

1. Let’s Encrypt certificates expire after 90 days. Short expiration periods are
   good for security, but they also mean that it’s important to automatically renew
   them to avoid regular maintenance work.

   Zulip configures automatic renewal for you. As a result, a Zulip server
   configured with Certbot does not require any ongoing work to maintain a
   current valid SSL certificate.

## Manually configuring certificates

It is possible, although not recommended, to obtain and manage TLS certificates
for Zulip yourself:

1. Set, in your `compose.override.yaml`:

   ```yaml
   services:
     zulip:
       environment:
         CERTIFICATES: manual
   ```

1. In the `zulip` Docker volume, place the certificate in
   `certs/manual/zulip.combined-chain.crt`, and the key in
   `certs/manual/zulip.key`. Because the volume is mounted in the `zulip`
   container under `/data/`, you can copy files into a running Zulip Docker
   instance via:

   ```bash
   docker compose cp /path/to/zulip.crt zulip:/data/certs/manual/zulip.combined-chain.crt
   docker compose cp /path/to/zulip.key zulip:/data/certs/manual/zulip.key
   ```

   This copying is only necessary once; since Docker volumes persist their data,
   the certificate will still be available even if the container is destroyed
   and recreated.

1. Restart your Zulip Docker deploy:

   ```bash
   docker compose up zulip
   ```

1. You are responsible for keeping the certificates up to date. When you renew
   the certificate, you must copy the new certificate into the volume, and
   restart the service:

   ```bash
   docker compose restart zulip
   ```

(proxies)=

## Deploying behind a reverse proxy

Before placing Zulip behind a reverse proxy, it needs to be configured to trust
the client IP addresses that the proxy reports via the `X-Forwarded-For` header,
and the protocol reported by the `X-Forwarded-Proto` header. This is important
to have accurate IP addresses in server logs, as well as in notification emails
which are sent to end users. Zulip doesn't default to trusting all
`X-Forwarded-*` headers, because doing so would allow clients to spoof any IP
address, and claim connections were over a secure connection when they were not;
we specify which IP addresses are the Zulip server's incoming proxies, so we
know which `X-Forwarded-*` headers to trust.

1. Determine the IP addresses of all reverse proxies you are setting up, as seen
   from the Zulip container. You can also determine the subnet that the reverse
   proxies will be on, and specify that (using CIDR notation).

1. Set the `LOADBALANCER_IPS` environment variable for the container to the IP
   address (or CIDR IP address range) of your reverse proxy:

   ```yaml
   services:
     zulip:
       environment:
         LOADBALANCER_IPS: 192.168.0.100
   ```

   Alternately, you can configure Docker Zulip to automatically trust its NAT
   gateway IP address, using `TRUST_GATEWAY_IP`:

   ```yaml
   services:
     zulip:
       environment:
         TRUST_GATEWAY_IP: True
   ```

1. Restart the server for the new settings:

   ```bash
   docker compose up zulip`
   ```

1. Configure your reverse proxy to send `X-Forwarded-For` and
   `X-Forwarded-Proto` headers. See
   {doc}`Zulip's guide to reverse proxies <zulip:production/reverse-proxies>`
   for details.

## See also

- [Merging Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- [Reference syntax for merging Compose files](https://docs.docker.com/reference/compose-file/merge/)
- [How Let's Encrypt works](https://letsencrypt.org/how-it-works/)
- {doc}`Zulip's guide to reverse proxies <zulip:production/reverse-proxies>`
- {doc}`compose-getting-started`

```

```
