# Upgrading instructions for `docker-compose`

You can upgrade your Zulip installation to any newer version of Zulip with the
following instructions. At a high level, the strategy is to download a new
image, stop the `zulip` container, and then boot it back up with the new
image. When the upgraded `zulip` container boots the first time, it will run the
necessary database migrations with `manage.py migrate`.

If you ever find you need to downgrade your Zulip server, you'll need to use
`manage.py migrate` to downgrade the database schema manually.

All of the instructions below assume you are using the provided
`docker-compose.yml`.

## Upgrading to a release

0. (Optional) Upgrading does not delete your data, but it's generally good
   practice to [back up your Zulip
   data](http://zulip.readthedocs.io/en/latest/prod-maintain-secure-upgrade.html#backups)
   before upgrading to make switching back to the old version simple. You can
   find your docker data volumes by looking at the `volumes` lines in
   `docker-compose.yml` e.g. `/opt/docker/zulip/postgresql/data/`.

   Note that `docker-zulip` did not support for Zulip's built-in
   `restore-backup` tool before Zulip 3.0.

1. Pull the new image version, e.g. for `2.0.8` run:

   ```shell
   docker pull zulip/docker-zulip:2.0.8-0
   ```

   We recommend always upgrading to the latest minor release within a major
   release series.

2. Update this project to the corresponding `docker-zulip` version and resolve
   any merge conflicts in `docker-compose.yml`. This is important as new Zulip
   releases may require additional settings to be specified in
   `docker-compose.yml` (E.g. authentication settings for `memcached` became
   mandatory in the `2.1.2` release).

   **Note:** Do not make any changes to the database version or volume. If there
   is a difference in database version, leave those unchanged for now, and
   complete that upgrade separately after the Zulip upgrade; see [the section
   below][pg-upgrade].

   [pg-upgrade]: #upgrading-zulipzulip-postgresql-to-14-version-60-0-and-above

3. Verify that your updated `docker-compose.yml` points to the desired image
   version, e.g.:

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

## Upgrading from a Git repository

1. Edit `docker-compose.yml` to comment out the `image` line, and specify the
   Git commit you'd like to build the zulip container from. E.g.:

   ```yaml
   zulip:
     # image: "zulip/docker-zulip:2.0.1-0"
     build:
       context: .
       args:
         # Change these if you want to build zulip from a different repo/branch
         ZULIP_GIT_URL: https://github.com/zulip/zulip.git
         ZULIP_GIT_REF: "refs/remotes/origin/master"
   ```

   You can set `ZULIP_GIT_URL` to any clone of the zulip/zulip git repository,
   and `ZULIP_GIT_REF` to be any fully qualified git ref name in that repository
   (e.g. `refs/remotes/origin/master` or `refs/remotes/origin/1.9.0`
   or `refs/remotes/origin/445932cc8613c77ced023125248c8b966b3b7528`).

2. Run `docker-compose build zulip` to build a Zulip Docker image from the
   specified Git version.

Then stop and restart the container as described in the previous section.

## Upgrading to use Docker volumes (version 6.0-0 and above)

As of Docker Zulip 6.0-0, we have switched the volume storage from being in
directories under `/opt/docker/zulip/` on the Docker host system, to using named
Docker managed volumes. In your `docker-compose.yml`, you should either preserve
the previous `/opt/docker/zulip/` paths for your volumes, or migrate the
contents to individual Docker volumes.

If you elect to switch to managed Docker volumes, you can copy the data out of
`/opt/docker/zulip` and onto managed volumes using the following:

```shell
# Stop the containers
docker-compose stop

# Copy the data into new managed volumes:
zulip_volume_sync() { docker run -it --rm -v "/opt/docker/zulip/$1:/src" -v "$(basename "$(pwd)")_${2:$1}":/dst ubuntu:20.04 sh -c 'cd /src; cp -a . /dst' ; }
zulip_volume_sync postgresql postgresql-10
zulip_volume_sync zulip
zulip_volume_sync rabbitmq
zulip_volume_sync redis

# Edit your `docker-compose.yml` to use, e.g. `postgresql-10:/var/lib/postgresql/data:rw`
# rather than `/opt/docker/zulip/postgresql/data:/var/lib/postgresql/data:rw` as a volume.
$EDITOR docker-compose.yml

# Start the containers again
docker-compose start
```

## Upgrading zulip/zulip-postgresql to 14 (version 6.0-0 and above)

As of Docker Zulip 6.0-0, we have upgraded the version of PostgreSQL which our
docker-compose configuration uses, from PostgreSQL 10 (which is no longer
supported) to PostgreSQL 14. Because the on-disk storage is not compatible
between PostgreSQL versions, this requires more than simply switching which
PostgreSQL docker image is used — the data must be dumped from PostgreSQL 10,
and imported into a running PostgreSQL 14.

You should not adjust the `image` of the database when upgrading to Zulip Server
6.0.

After upgrading the `zulip` service, using the usual steps, to the
`zulip/docker-zulip:6.0-0` tag, you can upgrade the PostgreSQL image version by
running the included `./upgrade-postgresql` tool. This will create a
Docker-managed volume named `postgresql-14` to store its data, and will adjust
the `docker-compose.yml` file to use that.

You can perform this step either before or after updating to use Docker volumes
(above). In either case, the updated `docker-compose.yml` will use a new Docker
volume for the upgraded PostgreSQL 14 data.

The `upgrade-postgresql` tool requires `docker-compose` 2.1.1 or higher.

If the tool does not work, you have too old a `docker-compose`, or you would
prefer to perform the steps manually, see the steps below. These instructions
assume that you have not changed the default Postgres data path
(`/opt/docker/zulip/postgresql/data`) in your `docker-compose.yml`. If you have
changed it, please replace all occurrences of
`/opt/docker/zulip/postgresql/data` with your path, or volume.

1. Make a backup of your Zulip Postgres data directory.

2. Stop the Zulip container:

   ```shell
   docker-compose stop zulip
   ```

3. Create a new (upgraded) Postgres container using a different data directory:

   ```shell
   docker run -d \
         --name postgresnew \
         -e POSTGRES_DB=zulip \
         -e POSTGRES_USER=zulip \
         -e POSTGRES_PASSWORD=zulip \
         -v "$(basename "$(pwd)")_postgresql-14:/var/lib/postgresql/data:rw" \
         zulip/zulip-postgresql:14
   ```

4. Use `pg_dumpall` to dump all data from the existing Postgres container to the
   new Postgres container, and reset the password (for SCRAM-SHA-256 auth
   upgrade):

   ```shell
   docker-compose exec database pg_dumpall -U zulip | \
       docker exec -i postgresnew psql -U zulip

   echo "ALTER USER zulip WITH PASSWORD 'REPLACE_WITH_SECURE_POSTGRES_PASSWORD';" |
       docker exec -i postgresnew psql -U zulip
   ```

5. Stop and remove both Postgres containers:

   ```shell
   docker-compose rm --stop database
   docker stop postgresnew
   docker rm postgresnew
   ```

6. Edit your `docker-compose.yml` to use the `zulip/zulip-postgresql:14` image
   for the `database` container.

7. Edit your `docker-compose.yml` to provide
   `postgresql-14:/var/lib/postgresql/data:rw` as the `volume` for the
   `database` service.

8. Start Zulip up again:
   ```shell
   docker-compose up
   ```

## Upgrading from the old galexrt/docker-zulip

If you are using an earlier version of `galexrt/docker-zulip` which used the
`quay.io/galexrt/postgres-zulip-tsearchextras:latest` PostgreSQL image, you need
to run a few manual steps to upgrade to the `zulip/zulip-postgresql` PostgreSQL
image (because we've significantly upgraded the major postgres version).

These instructions assume that you have not changed the default PostgreSQL data
path (`/opt/docker/zulip/postgresql/data`) in your `docker-compose.yml`. If you
have changed it, please replace all occurences of
`/opt/docker/zulip/postgresql/data` with your path.

1. Make a backup of your Zulip PostgreSQL data directory.

2. Stop all Zulip containers, except the postgres one (e.g. use `docker stop`
   and not `docker-compose stop`).

3. Create a new (upgraded) PostgreSQL container using a different data
   directory:

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

6. Edit your `docker-compose.yml` to use the `zulip/zulip-postgresql:latest`
   image for the `database` container (this is the default in
   `zulip/docker-zulip`).

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
