# Compose: Outgoing proxies

Zulip uses [Smokescreen][smokescreen] to proxy all outgoing HTTP connections and
prevent SSRF attacks. By default, Smokescreen denies access to all non-public IP
addresses, including 127.0.0.1, but allows traffic to all public Internet
hosts. If you wish to allow access to some private IPs (e.g., outgoing webhook
hosts on private IPs), you can set `CONFIG_http_proxy__allow_addresses` or
`CONFIG_http_proxy__allow_ranges` environment variables to comma-separated lists
of IP addresses or CIDR ranges.

For example, if you have an outgoing webhook at `http://10.17.17.17:80/`, a
partial `compose.override.yaml` configuration would be:

```yaml
service:
  zulip:
    environment:
      CONFIG_http_proxy__allow_addresses: 10.17.17.17
```

## See also

- {doc}`zulip:production/deployment`
- {doc}`zulip:production/system-configuration`

[smokescreen]: https://github.com/stripe/smokescreen
