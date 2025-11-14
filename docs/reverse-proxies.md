# Reverse proxies and certificates

By default, the Docker image will serve content on port 443 with a self-signed
certificate. It will expose port 80, port 443, and port 25 to the host. Port
80 will serve redirects to port 443 of the `EXTERNAL_HOST`.

## Direct public exposure with certbot

If the Docker host is the host which resolves to the `EXTERNAL_HOST`, that
hostname is accessible from the public Internet, and only serves you can adjust `docker-zulip`
to serve a [Let's Encrypt](https://letsencrypt.org/) certificate, which will be
auto-renewed.

The partial override configuration for that would be:

```yaml
services:
  zulip:
    environment:
      SSL_CERTIFICATE_GENERATION: certbot
```

By using `certbot` here, you are agreeing to the [Let's Encrypt
ToS](https://community.letsencrypt.org/tos).

## Direct exposure with manual certificates

If `EXTERNAL_HOST` is not publicly accessible, or you do not wish to use
certbot, you can opt to install certificates manually into the `zulip` volume.

:::{attention}
TODO: Test this
:::

## SSL termination at reverse proxy on Docker host

If you deploy `docker-zulip` behind a proxy on the Docker host which does TLS
termination, you should instruct it to only expose port 80, and to trust
`X-Forwarded-*` HTTP headers from the host's gateway IP.

```yaml
services:
  zulip:
    ports: !override
      - 8080:80
    environment:
      DISABLE_HTTPS: True
      TRUST_GATEWAY_IP: True
```

Your reverse proxy must provide both `X-Forwarded-For` and `X-Forwarded-Proto`
headers. See the Zulip documentation for sample [nginx][nginx-proxy],
[Apache2][apache2-proxy], and [HAProxy][haproxy-proxy] configurations, as well
as notes for [other proxies][other-proxy].

## SSL termination at reverse proxy within Docker

If you deploy `docker-zulip` behind a proxy within Docker which does TLS
termination, you should instruct it to not expose any ports, and to trust
`X-Forwarded-*` HTTP headers from the host's IP address (or IP address range).

```yaml
services:
  zulip:
    ports: !reset []
    environment:
      DISABLE_HTTPS: True
      # Replace this IP address range with the one for your subnet
      LOADBALANCER_IPS: 172.16.0.0/20
```

Your reverse proxy must provide both `X-Forwarded-For` and `X-Forwarded-Proto`
headers. See the Zulip documentation for sample [nginx][nginx-proxy],
[Apache2][apache2-proxy], and [HAProxy][haproxy-proxy] configurations, as well
as notes for [other proxies][other-proxy].

[nginx-proxy]: https://zulip.readthedocs.io/en/latest/production/reverse-proxies.html#nginx-configuration
[apache2-proxy]: https://zulip.readthedocs.io/en/latest/production/reverse-proxies.html#apache2-configuration
[haproxy-proxy]: https://zulip.readthedocs.io/en/latest/production/reverse-proxies.html#haproxy-configuration
[other-proxy]: https://zulip.readthedocs.io/en/latest/production/reverse-proxies.html#other-proxies
