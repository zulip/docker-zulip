# Docker Zulip environment variables

## `settings.py` values

If `MANUAL_CONFIGURATION` is not set, all variables starting with `SETTING_` are
mapped to [server configuration settings](inv:zulip:*#production/settings).

## `zulip.conf` values

If `MANUAL_CONFIGURATION` is not set, all variables starting with `CONFIG_` are
mapped to [system configuration
settings](inv:zulip:*#production/system-configuration). The section and setting
name are separated by `__` (two underscores).

## `zulip-secrets.conf` values

If `MANUAL_CONFIGURATION` is not set, all variables starting with `SECRET_` are
mapped to Zulip secrets, in `/etc/zulip/zulip-secrets.conf`.

## Specific settings

### `AUTO_BACKUP_ENABLED`

If set to True (the default), then will take database backups on an interval
controlled by `AUTO_BACKUP_INTERVAL`. These backups will be stored, named by
their timestamp, in `/data/backups/`.

Note that these backups contain _only_ the database. The configuration and
user-uploaded files (stored by default in the named Docker volume) must be
backed up separately.

### `AUTO_BACKUP_INTERVAL`

A `cron`-style string describing the cadence on which automated database backups
will be taken. Defaults to daily at 3:30am UTC (i.e. `30 3 * * *`).

### `CERTIFICATES`

One of the following values:

- "": The default is the empty string, which means that the Zulip docker
  container will serve content on port 80, unencrypted. This deployment must be
  placed behind a [SSL-terminating proxy](#proxies) to function correctly.

- `self-signed`: A self-signed, 10-year certificate will be generated and used.
  It will be stored in `/data/certs/self-signed/`

- `certbot`: A Let's Encrypt certificate will be provisioned, using your
  configured `SETTING_EXTERNAL_HOST` value, and validated using an [`HTTP-01`
  challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge).
  This requires that the external hostname be accessible via the public
  Internet. The certificate, key, and Lets Encrypt configuration will be stored
  under `/data/certs/letsencrypt/`.

  :::{admonition} Let's Encrypt Terms of Service
  Enabling this configuration will create an account with Let's Encrypt, using
  Zulip's server administrator email address, and will accept [their Terms of
  Service](https://letsencrypt.org/repository/#let-s-encrypt-subscriber-agreement).
  :::

- `manual`: You must provide a certificate in
  `/data/certs/manual/zulip.combined-chain.crt` and a key in
  `/data/certs/manual/zulip.key`.

:::{seealso}

- {doc}`/how-to/compose-ssl`

:::

### `LINK_SETTINGS_TO_DATA`

The server's configuration will be stored in the named Docker volume, under the
`etc-zulip/` directory. This is generally only useful in conjunction with
`MANUAL_CONFIGURATION`.

:::{seealso}

- {doc}`/how-to/compose-manual-configuration`

:::

### `LOADBALANCER_IPS`

The comma-separated list of IP addresses to trust the `X-Forwarded-For` headers
from.

:::{seealso}

- [](#proxies)
- {doc}`zulip:production/reverse-proxies`

:::

### `MANUAL_CONFIGURATION`

All `SETTING_`, `CONFIG_`, and `SECRET_` environment keys are ignored, and
`/etc/zulip/settings.py` and `/etc/zulip/zulip-secrets.conf` in the container
are the authoritative sources of the configuration. This is generally useful if
you want to manage the files externally, or need to set up more complicated
Zulip settings which are too complicated to do via environment variables.

Often used in conjunction with `LINK_SETTINGS_TO_DATA`, but can also be used
with extra bind mounts to place external files into `/etc/zulip/`.

:::{seealso}

- {doc}`/how-to/compose-manual-configuration`

:::

### `CONFIG_application_server__queue_workers_multiprocess`

By default, the Zulip server automatically detects whether the system has enough
memory to run Zulip queue processors in the higher-throughput but more
multiprocess mode -- or if it should save a significant amount of RAM, and use
the lower-throughput multi-threaded mode. If the `zulip` container does not have
a [`memory` resource limit][memory-limit] set, this algorithm will see the
**host's** memory, not the docker container's memory, and will likely default to
the heavier-weight multiprocess mode. Set to `True` or `False` to override the
automatic calculation.

[memory-limit]: https://docs.docker.com/reference/compose-file/deploy/#memory

### `TRUST_GATEWAY_IP`

Set to `True` to automatically add the gateway IP address to `LOADBALANCER_IPS`.
This is often a simple shortcut to trust all NAT'd traffic into the container.

:::{seealso}

- [](#proxies)

:::

### `ZULIP_AUTH_BACKENDS`

A comma-separated list of authentication backends to enable. Note that this
takes the place of `SETTING_AUTHENTICATION_BACKENDS`. This
defaults to just `EmailAuthBackend`.

:::{seealso}

- {doc}`/how-to/compose-authentication`

:::

### `ZULIP_CUSTOM_SETTINGS`

A string of additional Python code, which is appended to the generated
`setting.py` file. This is a slightly simpler form of advanced configuration
than `MANUAL_CONFIGURATION`.

Because this is Python code, the variables set in this should _not_ be prefixed
with `SETTING_`.

For example:

```yaml
services:
  zulip:
    environment:
      ZULIP_CUSTOM_SETTINGS: |
        AUTH_LDAP_USER_SEARCH = LDAPSearch(
            "ou=users,dc=example,dc=com", ldap.SCOPE_SUBTREE, "(uid=%(user)s)"
        )
```

:::{seealso}

- {doc}`/how-to/compose-manual-configuration`
- {doc}`zulip:production/settings`
- [The default template `settings.py` file](zulip-repo-raw:zproject/prod_settings_template.py)

:::

### `ZULIP_RUN_POST_SETUP_SCRIPTS`

By default, the Zulip Docker container will run all executable scripts found in
`/data/post-setup.d/`, after running all of its configuration steps. You can set
this to `False` to skip this behavior.

## See also

- {doc}`/how-to/compose-settings`
- {doc}`/how-to/compose-manual-configuration`
- {doc}`/how-to/compose-secrets`
