## Upgrading the Zulip container

You can upgrade your Zulip installation to any newer version of Zulip
with the following instructions. At a high level, the strategy is to
download a new image, stop the `zulip` container, and then boot it
back up with the new image. When the upgraded `zulip` container boots
the first time, it will run the necessary database migrations with
`manage.py migrate`.

If you ever find you need to downgrade your Zulip server, you'll need
to use `manage.py migrate` to downgrade the database schema manually.

If you are using old `galexrt/docker-zulip` images (from Zulip 1.8.1 or
older), you need to upgrade the postgres image from
`quay.io/galexrt/postgres-zulip-tsearchextras:latest`. Refer to the
[instructions for upgrading from the old galexrt/docker-zulip](#upgrading-from-the-old-galexrtdocker-zulip)
section.

### Using `docker-compose`

0. (Optional) Upgrading does not delete your data, but it's generally
   good practice to
   [back up your Zulip data](http://zulip.readthedocs.io/en/latest/prod-maintain-secure-upgrade.html#backups)
   before upgrading to make switching back to the old version
   simple. You can find your docker data volumes by looking at the
   `volumes` lines in `docker-compose.yml`
   e.g. `/opt/docker/zulip/postgresql/data/`.

   Note that `docker-zulip` did not support for Zulip's built-in
   `restore-backup` tool before Zulip 3.0.

1. Pull the new image version, e.g. for `2.0.8` run: `docker pull zulip/docker-zulip:2.0.8-0`. We recommend always upgrading to the
   latest minor release within a major release series.

2. Update this project to the corresponding `docker-zulip` version and
   resolve any merge conflicts in `docker-compose.yml`.
   This is important as new Zulip releases may require additional
   settings to be specified in `docker-compose.yml`
   (E.g. authentication settings for `memcached` became mandatory in
   the `2.1.2` release).

   **Note:** Do not make any changes to the database version or
   volume. If there is a difference in database version, leave those
   unchanged for now, and complete that upgrade separately after the
   Zulip upgrade; see [the section below][pg-upgrade].

   [pg-upgrade]: #upgrading-zulipzulip-postgresql-to-14

3. Verify that your updated `docker-compose.yml` points to the desired image version,
   e.g.:

   ```yaml
   zulip:
     image: "zulip/docker-zulip:2.0.1-0"
   ```

4. You can execute the upgrade by running:

   ```shell
   # Stops the old zulip container; this begins your downtime
   docker-compose stop
   # Boots the new zulip container; this ends your downtime
   docker-compose up
   # Deletes the old container images
   docker-compose rm
   ```

That's it! Zulip is now running the updated version.
You can confirm you're running the latest version by running:

```shell
docker-compose exec -u zulip zulip cat /home/zulip/deployments/current/version.py
```

### Upgrading from a Git repository

1. Edit `docker-compose.yml` to comment out the `image` line, and
   specify the Git commit you'd like to build the zulip container from.
   E.g.:

   ```yaml
   zulip:
     # image: "zulip/docker-zulip:2.0.1-0"
     build:
       context: .
       args:
         # Change these if you want to build zulip from a different repo/branch
         ZULIP_GIT_URL: https://github.com/zulip/zulip.git
         ZULIP_GIT_REF: master
   ```

   You can set `ZULIP_GIT_URL` to any clone of the zulip/zulip git repository,
   and `ZULIP_GIT_REF` to be any ref name in that repository (e.g. `master` or
   `1.9.0` or `445932cc8613c77ced023125248c8b966b3b7528`).

2. Run `docker-compose build zulip` to build a Zulip Docker image from
   the specified Git version.

Then stop and restart the container as described in the previous section.

### Upgrading zulip/zulip-postgresql to 14

The Docker Compose configuration for version 6.0-0 and higher default
to using PostgreSQL 14, as the previously-used PostgreSQL 10 is no
longer supported. Because the data is specific to the version of
PostgreSQL which is running, it must be dumped and re-loaded into a
new volume to upgrade. PostgreSQL 14 will refuse to start if provided
with un-migrated data from PostgreSQL 10.

The provided `upgrade-postgresql` tool will dump the contents of the
`postgresql` image's volume, create a new PostgreSQL 14 volume,
perform the necessary migration, update the `docker-compose.yml`
file to match, and re-start Zulip.

### Upgrading from the old galexrt/docker-zulip

If you are using an earlier version of `galexrt/docker-zulip` which
used the `quay.io/galexrt/postgres-zulip-tsearchextras:latest`
PostgreSQL image, you need to run a few manual steps to upgrade to the
`zulip/zulip-postgresql` PostgreSQL image (because we've significantly
upgraded the major postgres version).

These instructions assume that you have not changed the default
PostgreSQL data path (`/opt/docker/zulip/postgresql/data`) in your
`docker-compose.yml`. If you have changed it, please replace all
occurences of `/opt/docker/zulip/postgresql/data` with your path.

1. Make a backup of your Zulip PostgreSQL data dir.

2. Stop all Zulip containers, except the postgres one (e.g. use
   `docker stop` and not `docker-compose stop`).

3. Create a new (upgraded) PostgreSQL container using a different data directory:

   ```shell
   docker run -d \
         --name postgresnew \
         -e POSTGRES_DB=zulip \
         -e POSTGRES_USER=zulip \
         -e POSTGRES_PASSWORD=zulip \
         -v /opt/docker/zulip/postgresql/new:/var/lib/postgresql/data:rw \
         zulip/zulip-postgresql:latest
   ```

4. Use `pg_dumpall` to dump all data from the existing PostgreSQL container to
   the new PostgreSQL container:

   ```shell
   docker-compose exec database pg_dumpall -U postgres | \
       docker exec -i postgresnew psql -U postgres
   ```

5. Stop and remove both PostgreSQL containers:

   ```shell
   docker-compose rm --stop database
   docker rm --stop postgresnew
   ```

6. Edit your `docker-compose.yml` to use the
   `zulip/zulip-postgresql:latest` image for the `database` container
   (this is the default in `zulip/docker-zulip`).

7. Replace the old PostgreSQL data directory with upgraded data directory:

   ```shell
   mv /opt/docker/zulip/postgresql/data /opt/docker/zulip/postgresql/old
   mv /opt/docker/zulip/postgresql/new /opt/docker/zulip/postgresql/data
   ```

8. Delete the old existing containers:

   ```shell
   docker-compose rm
   ```

9. Start Zulip up again:

   ```shell
   docker-compose up
   ```

That should be it. Your PostgreSQL data has now been updated to use the
`zulip/zulip-postgresql` image.
