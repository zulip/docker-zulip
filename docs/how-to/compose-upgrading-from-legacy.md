# Compose: Upgrading from the legacy `zulip/docker-zulip` image

Zulip Server 11.x and earlier shipped as `zulip/docker-zulip` on
Docker Hub. The 12.x series moved to `ghcr.io/zulip/zulip-server`,
with a number of breaking configuration changes along the way. This
page covers the one-time work needed to migrate; once you're on the
new image, future upgrades follow the standard
{doc}`compose-upgrading` flow.

If you've already migrated, you don't need this page.

## Plan and back up

1. **Back up first.** This is a major upgrade and the volume layout
   changes (see below); a backup is the simplest way to make rolling
   back tractable. See [backing up Zulip data](https://zulip.readthedocs.io/en/latest/production/export-and-import.html#backups).

   ```bash
   docker compose exec zulip /sbin/entrypoint.sh app:backup
   docker compose run --rm -v zulip:/data -v $(pwd):/backup zulip \
     tar czf /backup/backup.tar.gz -C /data .
   ```

1. **Snapshot your current configuration.** The checkout in the next
   section will overwrite your edited `docker-compose.yml`. Save a
   reference copy first so you can translate settings from it:

   ```bash
   cp docker-compose.yml ../docker-compose.yml.legacy-backup
   ```

## What changed

### Image

`zulip/docker-zulip` on Docker Hub is replaced by
`ghcr.io/zulip/zulip-server` on GitHub Container Registry. The Docker
Hub image will receive no further updates after the Zulip Server 11.x
series is end-of-life.

### Configuration layout

- Local configurations are expected to live in `compose.override.yaml`,
  which you copy from the tracked `compose.override.yaml.example`
  template. The shipped `compose.yaml` is no longer expected to be
  edited.

- Secrets are no longer environment variables in two places in
  `compose.yaml`; they have moved to use Docker secrets. See
  {doc}`compose-secrets`.

### Setting renames and removals

- `DB_HOST` and `DB_HOST_PORT` have been replaced by
  `SETTING_REMOTE_POSTGRES_HOST` and `SETTING_REMOTE_POSTGRES_PORT`,
  respectively, to align with standard Zulip settings.

- `DB_USER` and `DB_NAME` have been replaced with
  `CONFIG_postgresql__database_user` and
  `CONFIG_postgresql__database_name`, respectively.

- `REMOTE_POSTGRES_SSLMODE` has been removed; the standard spelling
  `SETTING_REMOTE_POSTGRES_SSLMODE` is used instead.

- `DISABLE_HTTPS` and `SSL_CERTIFICATE_GENERATION` have been replaced
  with the single `CERTIFICATES` setting; the default is now
  HTTP-only, since most Docker deployments are behind an existing
  proxy. See {doc}`compose-ssl`.

- `SPECIAL_SETTING_DETECTION_MODE` has been removed; its behavior was
  confusing and at odds with its name.

- `NGINX_PROXY_BUFFERING` has been removed; setting it could only
  break things.

- `NGINX_WORKERS` has been replaced with the generic
  `CONFIG_application_server__nginx_worker_processes`.

- `PROXY_ALLOW_ADDRESSES` and `PROXY_ALLOW_RANGES` have been replaced
  with the generic `CONFIG_http_proxy__allow_addresses` and
  `CONFIG_http_proxy__allow_ranges`.

- `QUEUE_WORKERS_MULTIPROCESS` has been replaced with the generic
  `CONFIG_application_server__queue_workers_multiprocess`.

### Volume layout

Contents of the named `zulip` Docker volume have been reorganized:
certificates are stored in `certs/` subdirectories (`self-signed`,
`certbot`, and `manual`), and `LINK_SETTINGS_TO_DATA` contents are
stored in `etc-zulip/` rather than `settings/etc-zulip/`. Files are
moved to these new locations automatically on first startup with the
new image.

## Migrate to the 12.x layout

1. **Discard local edits to the tracked compose file.** `git checkout`
   refuses to overwrite a file with uncommitted modifications, and you
   already have your reference copy saved from the previous section.
   Either reset:

   ```bash
   git checkout -- docker-compose.yml
   ```

   or stash:

   ```bash
   git stash push -m "legacy compose customizations" docker-compose.yml
   ```

1. **Fetch and check out the first 12.x release tag**, on a local
   branch so subsequent upgrades follow the same pattern:

   ```bash
   git fetch --tags
   git checkout -B release 12.0-0
   ```

   The compose configuration file is now `compose.yaml` (not
   `docker-compose.yml`).

1. **Move your secrets into a `.env` file.** See
   {ref}`secrets-env-file` for the full mapping; copy each `ZULIP__*`
   value out of your old `docker-compose.yml.legacy-backup` and into
   `.env`.

1. **Build your override file from the example, then translate
   settings:**

   ```bash
   cp compose.override.yaml.example compose.override.yaml
   ```

   Edit it to translate your previous local settings, applying the
   renames in the section above. The skeleton looks like:

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
   services:
     zulip:
       environment:
         # Include all settings starting with SETTING_ from your old
         # docker-compose.yml, plus any of the renamed settings above.
   ```

1. **Set `CERTIFICATES` if needed.** If you had _not_ previously set
   `DISABLE_HTTPS`, or had set `SSL_CERTIFICATE_GENERATION`, you will
   need to set `CERTIFICATES`; see {doc}`compose-ssl`.

## Bring the new image up

```bash
docker compose pull
docker compose up -d
```

The first boot performs the volume reorganization described above,
along with any database migrations. Watch the logs with
`docker compose logs -f zulip`, looking for
`=== End Initial Configuration Phase ===` to confirm a clean start.

## See also

- {doc}`compose-upgrading`
- {doc}`compose-secrets`
- {doc}`compose-ssl`
