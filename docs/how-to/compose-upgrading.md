# Compose: Upgrading

Upgrades work by checking out a newer release of this repository,
which updates `compose.yaml` to reference the new image tag, then
pulling that image and restarting the container. When the upgraded
`zulip` container boots the first time, it runs the necessary database
migrations.

The git ref of this repository is the version-of-record for your
deployment: pinning a specific tag like `{{ DOCKER_VERSION }}` ensures that the
`compose.yaml`, the example override file, and the image tag are all
mutually consistent. See {doc}`/reference/versioning` for a full
explanation of the tag scheme.

If you ever find you need to downgrade your Zulip server, you'll need
to use `manage.py migrate` to downgrade the database schema manually.

:::{tip}
If you're moving from the legacy `zulip/docker-zulip` packaging on
Docker Hub (Zulip Server 11.x and earlier), see
{doc}`compose-upgrading-from-legacy` first — it covers the one-time
configuration changes you'll need to make before you can use this
flow.
:::

## Upgrading to a release

1. (Optional) Upgrading does not delete your data, but it's generally
   good practice to back up before upgrading. Refresh the database
   dump and snapshot the `/data` volume:

   ```bash
   docker compose exec zulip /sbin/entrypoint.sh app:backup
   docker compose run --rm -v zulip:/data -v $(pwd):/backup zulip \
     tar czf /backup/backup.tar.gz -C /data .
   ```

   See {doc}`compose-backups` for the full backup-and-restore flow.

1. Check out the release you want to upgrade to, on a local branch
   that you can re-point at each subsequent release. Tag names match
   the image tag exactly:

   ```bash
   git fetch --tags
   git checkout -B release {{ DOCKER_VERSION }}
   ```

   The
   [GitHub releases page](https://github.com/zulip/docker-zulip/releases)
   lists available tags. We recommend always upgrading to the latest
   minor release within a major release series. We do not publish
   floating tags; see {doc}`/reference/versioning`.

   :::{note}
   `compose.override.yaml` is gitignored, so the checkout will not
   touch your local edits. To pick up any new commented-out options
   that the new release added to the example file, diff them:

   ```bash
   diff compose.override.yaml.example compose.override.yaml
   ```

   Copy any new lines you want into your `compose.override.yaml`.
   :::

1. Pull the new image and restart the container:

   ```bash
   docker compose pull
   docker compose up -d
   ```

## Upgrading from a Git repository

You can build the image yourself from a specific Zulip git ref —
useful for testing a development branch or running a local fork.

1. Edit `compose.override.yaml`, and specify the Git commit you'd like
   to build the zulip container from, via the `ZULIP_GIT_REF` build
   argument. For example:

   ```yaml
   services:
     zulip:
       image: ghcr.io/zulip/zulip-server:main
       build:
         args:
           # Change these if you want to build zulip from a different repo/branch
           ZULIP_GIT_URL: https://github.com/zulip/zulip.git
           ZULIP_GIT_REF: main
   ```

   You can set `ZULIP_GIT_URL` to any clone of the zulip/zulip git
   repository, and `ZULIP_GIT_REF` to be any ref name in that
   repository (e.g. `main` or `12.0` or
   `445932cc8613c77ced023125248c8b966b3b7528`).

1. Build the image:

   ```bash
   docker compose build zulip
   ```

1. Update the running Docker Compose instance with that image; this
   will run database migrations, etc:

   ```bash
   docker compose up -d
   ```

## Troubleshooting

### `git checkout` refuses with "local changes would be overwritten"

If you cloned this repository before `compose.override.yaml` became
gitignored, your `compose.override.yaml` is still a tracked file with
local edits, and `git checkout` refuses to overwrite them. Set the
file aside, reset the tracked version so the checkout can proceed,
do the checkout, then move your edits back:

```bash
cp compose.override.yaml compose.override.yaml.local-backup
git checkout HEAD -- compose.override.yaml
git checkout -B release {{ DOCKER_VERSION }}
mv compose.override.yaml.local-backup compose.override.yaml
```

After the new branch is checked out, `compose.override.yaml` is no
longer tracked (the release tag has the file gitignored), so the
final `mv` puts your edits in the right place — untracked on disk,
picked up by `docker compose` like any other override file.

## See also

- {doc}`compose-upgrading-from-legacy`
- {doc}`/reference/versioning`
