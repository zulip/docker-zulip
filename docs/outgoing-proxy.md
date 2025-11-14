# Outgoing proxies

Zulip uses [Smokescreen][smokescreen] to proxy all outgoing HTTP connections and
prevent SSRF attacks. By default, Smokescreen denies access to all non-public IP
addresses, including 127.0.0.1, but allows traffic to all public Internet
hosts. If you wish to allow access to some private IPs (e.g., outgoing webhook
hosts on private IPs), you can set `PROXY_ALLOW_ADDRESSES` or
`PROXY_ALLOW_RANGES` environment variables to comma-separated lists of IP
addresses or CIDR ranges.

For example, if you have an outgoing webhook at `http://10.17.17.17:80/`, a
partial override would be:

```yaml
service:
  zulip:
    environment:
      PROXY_ALLOW_ADDRESSES: 10.17.17.17
```

`PROXY_ALLOW_ADDRESSES` and `PROXY_ALLOW_RANGES` are the equivalents of
`http_proxy.allow_addresses` and `http_proxy.allow_ranges` in the [standard
Zulip configuration][core].

[smokescreen]: https://github.com/stripe/smokescreen
[core]: https://zulip.readthedocs.io/en/latest/production/deployment.html#customizing-the-outgoing-http-proxy
