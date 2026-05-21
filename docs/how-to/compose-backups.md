# Compose: Backups

Zulip's persistent state in a Compose deployment lives under the
`zulip` named Docker volume mounted at `/data`. A snapshot of that
volume captures everything Zulip needs to restore the deployment —
uploads, configuration, certificates, secrets, and a recent
`pg_dump` written into `/data/backups/` by the `app:backup` command.
See {doc}`/reference/data-volume` for the layout and the full backup
model.

(compose-volume-snapshot)=

## Take a backup

Refresh the database dump and snapshot the volume, using
[Docker's recommended pattern for backing up data volumes](https://docs.docker.com/engine/storage/volumes/#back-up-restore-or-migrate-data-volumes):

```bash
docker compose exec zulip /sbin/entrypoint.sh app:backup
docker compose run --rm -v zulip:/data -v $(pwd):/backup zulip \
  tar czf /backup/backup.tar.gz -C /data .
```

The first command writes a fresh `pg_dump` into `/data/backups/`; the
second mounts the named volume into an ephemeral container and tars
its contents out to `backup.tar.gz` in the host's current directory.

`app:backup` also runs on a daily schedule by default (see
{ref}`auto-backup-enabled` and {ref}`auto-backup-interval`), so the
volume already holds a reasonably fresh dump for on-demand snapshots;
the explicit `app:backup` call above just guarantees the dump is as
current as possible.

## Get just the database dump off-box

If you only need to ship the database dumps off-box, copy them out
directly:

```bash
docker compose cp zulip:/data/backups/ ./backups/
```

## Restore from a backup

Stop the Zulip container, restore the volume contents from the
tarball, then bring it back up:

```bash
docker compose stop zulip
docker compose run --rm -v zulip:/data -v $(pwd):/backup zulip \
  tar xzf /backup/backup.tar.gz -C /data
docker compose up -d zulip
```

The volume restore brings back uploads, configuration, certificates,
and the database dump in `/data/backups/`. The PostgreSQL data in
the `database` service's `postgresql-14` volume is _not_ touched by
this; to bring the database itself to a matching state, restore from
the dump inside the volume:

```bash
docker compose exec zulip /sbin/entrypoint.sh app:restore <filename>
```

where `<filename>` is one of the `backup-*.sql` files in the restored
`/data/backups/` directory. See {ref}`app:restore <app-restore>`.

## Off-site database backups

For continuous off-site database backups independent of the
volume-snapshot path, Zulip supports
{ref}`WAL-based archiving via wal-g <zulip:wal-g>`, which streams
write-ahead logs to S3 for point-in-time recovery.

## See also

- {doc}`/reference/data-volume`
- {doc}`/reference/app-commands`
- {doc}`compose-upgrading`
