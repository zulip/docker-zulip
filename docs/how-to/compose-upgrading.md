# Compose: Upgrading

You can upgrade your Zulip installation to any newer version of Zulip with the
following instructions. At a high level, the strategy is to download a new
image, stop the `zulip` container, and then boot it back up with the new
image. When the upgraded `zulip` container boots the first time, it will run the
necessary database migrations.

If you ever find you need to downgrade your Zulip server, you'll need to use
`manage.py migrate` to downgrade the database schema manually.

:::{tip}
If you're moving from the legacy `zulip/docker-zulip` packaging on
Docker Hub (Zulip Server 11.x and earlier), see
{doc}`compose-upgrading-from-legacy` first — it covers the one-time
configuration changes you'll need to make before you can use this
flow.
:::

## Upgrading to a release

1. (Optional) Upgrading does not delete your data, but it's generally good
   practice to [back up your Zulip data][backups] before upgrading to make
   switching back to the old version simple.

   You can back up your database onto the Docker Volume using:

   ```shell
   docker compose exec zulip /sbin/entrypoint.sh app:backup
   ```

   You can back up the contents of the Docker named volume itself:

   ```shell
   docker compose run --rm -v zulip:/data -v $(pwd):/backup zulip \
     tar czf /backup/backup.tar.gz -C /data .
   ```

1. Pull the new image version, e.g. for `12.0` run:

   ```shell
   docker pull ghcr.io/zulip/zulip-server:12.0-0
   ```

   We recommend always upgrading to the latest minor release within a major
   release series. The
   [GitHub releases page](https://github.com/zulip/docker-zulip/releases)
   lists available tags. See {doc}`/reference/versioning` for an explanation
   of the tag format and why no floating tags (such as `latest` or `12`) are
   published.

1. Update this repository to the corresponding `docker-zulip` version.
   Your `compose.override.yaml` is not tracked in git and will not be
   touched by the pull. To pick up any new commented-out options that
   the new release added to the example file, diff them:

   ```shell
   diff compose.override.yaml.example compose.override.yaml
   ```

   Copy any new lines you want into your `compose.override.yaml`.

   :::{note}
   If you cloned the repository before `compose.override.yaml` became a
   gitignored file, run this once to keep your local edits and let
   future pulls work cleanly:

   ```shell
   cp compose.override.yaml compose.override.yaml.bak
   git rm --cached compose.override.yaml
   git checkout compose.override.yaml.example
   mv compose.override.yaml.bak compose.override.yaml
   ```

   :::

1. You can execute the upgrade by running:

   ```shell
   # Restart the zulip container
   docker compose up
   ```

## Upgrading from a Git repository

1. Edit `compose.override.yaml`, and specify the Git commit you'd like to
   build the zulip container from, via the `ZULIP_GIT_REF` build argument.
   For example:

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

   You can set `ZULIP_GIT_URL` to any clone of the zulip/zulip git repository,
   and `ZULIP_GIT_REF` to be any ref name in that repository (e.g. `main` or
   `12.0` or `445932cc8613c77ced023125248c8b966b3b7528`).

2. Build the image:

   ```shell
   docker compose build zulip
   ```

3. Update the running Docker Compose instance with that image; this will run
   database migrations, etc:

   ```shell
   docker compose up
   ```
