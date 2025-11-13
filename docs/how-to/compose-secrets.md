# Compose: Secrets management

Zulip's Docker container uses Docker secrets to synchronize secrets between
services, as well as within Zulip itself. These secrets are used to authenticate
connections between services in the deployment, serving as defense in depth from
[SSRF][ssrf], as well as to authenticate to outside providers (e.g. outgoing
email services).

Docker Compose offers two backends for secrets -- from the environment, or from
files on disk.

[ssrf]: https://owasp.org/www-community/attacks/Server_Side_Request_Forgery

## Store secrets in a `.env` file

The simplest deployment technique is to provide secrets in the environment, most
commonly stored in an environment file. Note that is the environment for the
compose file itself, _not_ the environment of the container. Environment
variables defined in `.env` do _not_ directly propagate into the container's
environments.

Place in `compose.override.yaml` (alongside any other configuration):

```yaml
secrets:
  zulip__postgres_password:
    environment: "ZULIP__POSTGRES_PASSWORD"
  zulip__memcached_password:
    environment: "ZULIP__MEMCACHED_PASSWORD"
  zulip__rabbitmq_password:
    environment: "ZULIP__RABBITMQ_PASSWORD"
  zulip__redis_password:
    environment: "ZULIP__REDIS_PASSWORD"
  zulip__secret_key:
    environment: "ZULIP__SECRET_KEY"
  zulip__email_password:
    environment: "ZULIP__EMAIL_PASSWORD"
```

In a file named `.env` (which should not be checked into version control),
provide the secrets.

```
ZULIP__POSTGRES_PASSWORD=example_postgres_password
ZULIP__MEMCACHED_PASSWORD=example_memcached_password
ZULIP__RABBITMQ_PASSWORD=example_rabbitmq_password
ZULIP__REDIS_PASSWORD=example_redis_password

ZULIP__SECRET_KEY=example_django_secret_key

ZULIP__EMAIL_PASSWORD=example_outgoing_email_password
```

See the [`.env` file syntax][env-syntax] for a complete reference on the syntax.

[env-syntax]: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/#env-file-syntax

## Store secrets in files in a directory

Secrets can also be stored as flat files on disk, at paths of your choosing.

Place in `compose.override.yaml` (alongside any other configuration):

```yaml
secrets:
  zulip__postgres_password:
    file: /path/to/secrets/postgres
  zulip__memcached_password:
    file: /path/to/secrets/memcached
  zulip__rabbitmq_password:
    file: /path/to/secrets/rabbitmq
  zulip__redis_password:
    file: /path/to/secrets/redis
  zulip__secret_key:
    file: /path/to/secrets/django_key
  zulip__email_password:
    file: /path/to/secrets/outgoing_email
```

Then, in `/path/to/secrets/`, place each of those files. Take care to _not_
include trailing newlines in them; for example:

```shell
echo -n "example_postgres_password" > /path/to/secrets/postgres
```

## Additional secrets

If your deployment needs additional secrets, you must prefix them with
`zulip__`, and add them to the top-level `secrets` element, as well as the
`secrets` attribute for the `zulip` service.

For instance, to add a `giphy_api_key` secret, the `compose.override.yaml` might
contain:

```yaml
secrets:
  # Standard secrets
  zulip__postgres_password:
    environment: "ZULIP__POSTGRES_PASSWORD"
  zulip__memcached_password:
    environment: "ZULIP__MEMCACHED_PASSWORD"
  zulip__rabbitmq_password:
    environment: "ZULIP__RABBITMQ_PASSWORD"
  zulip__redis_password:
    environment: "ZULIP__REDIS_PASSWORD"
  zulip__secret_key:
    environment: "ZULIP__SECRET_KEY"
  zulip__email_password:
    environment: "ZULIP__EMAIL_PASSWORD"

  # New, additional secret
  zulip__giphy_api_key:
    environment: "ZULIP__GIPHY_API_KEY"

services:
  zulip:
    # Tell Docker Compose that the zulip container needs access to the additional secret
    secrets:
      - zulip__giphy_api_key
```

With an additional value in `.env`:

```
# Standard secrets
ZULIP__POSTGRES_PASSWORD=...
ZULIP__MEMCACHED_PASSWORD=...
ZULIP__RABBITMQ_PASSWORD=...
ZULIP__REDIS_PASSWORD=...
ZULIP__SECRET_KEY=...
ZULIP__EMAIL_PASSWORD=...

# Additional secret
ZULIP__GIPHY_API_KEY=PS42beKkLnOUBOqb1BgTyna87ooKgthE
```

## See also

- [How to use secrets in Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Secrets top-level element in `compose.yaml`](https://docs.docker.com/reference/compose-file/secrets/)
- [Secrets attribute for services top-level element in `compose.yaml`](https://docs.docker.com/reference/compose-file/services/#secrets)
- {doc}`compose-settings`
