# Compose: Remapping published ports

The default `compose.yaml` publishes the container's ports 25, 80, and
443 on the same host ports. If one of those host ports is already in
use -- for example, by a reverse proxy that listens on host port 80
-- you will need to publish Zulip on a different host port. See
{doc}`/reference/ports` for what each port is used for.

## Why redeclaring `ports` in `compose.override.yaml` does not work

Docker Compose
[merges](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
`compose.override.yaml` on top of `compose.yaml`, and by default
appends to lists rather than replacing them. Adding a `ports:` list
to `compose.override.yaml` therefore produces the concatenation of
the original mappings from `compose.yaml` and the new ones, and
Docker still tries to bind the original host ports. The result is
an error like:

```text
Bind for 0.0.0.0:80 failed: port is already allocated
```

## Replacing the `ports` list with `!override`

Docker Compose provides the
[`!override`](https://docs.docker.com/reference/compose-file/merge/#replace-value)
tag to replace a value entirely instead of merging it. Tag the
`ports` list in `compose.override.yaml` with `!override` to discard
the defaults from `compose.yaml` and use only the mappings listed
below:

```yaml
services:
  zulip:
    ports: !override
      - name: smtp
        target: 25
        published: 2525
        app_protocol: smtp
      - name: http
        target: 80
        published: 8080
        app_protocol: http
      - name: https
        target: 443
        published: 8443
        app_protocol: https
```

With this override, Docker publishes only the listed ports and
leaves host port 80 free for the reverse proxy.

If you do not need a port published on the host at all -- for
example, port 25 when you are not using the
{doc}`incoming email gateway <compose-incoming-email>` -- omit it
from the `!override` list.

The related
[`!reset`](https://docs.docker.com/reference/compose-file/merge/#reset-value)
tag removes a value entirely rather than replacing it; see
{doc}`compose-existing-services` for an example that uses it to
drop an inherited service.

## See also

- {doc}`/reference/ports`
- {doc}`compose-ssl`
- {doc}`compose-incoming-email`
- [Reference syntax for merging Compose files](https://docs.docker.com/reference/compose-file/merge/)
