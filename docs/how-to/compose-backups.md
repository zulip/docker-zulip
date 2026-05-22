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

With the stack stopped (or before bringing it up for the first time
on this host), untar the backup volume into a fresh `zulip` named
volume and restore the database from the dump inside it:

```bash
docker compose down -v               # wipe any existing state on this host
docker compose run --rm --no-deps -v zulip:/data -v $(pwd):/backup zulip \
  tar xzf /backup/backup.tar.gz -C /data
docker compose run --rm zulip app:restore <filename>
docker compose up -d --wait
```

`<filename>` is one of the `backup-*.sql` files in the restored
`/data/backups/` directory. See {ref}`app:restore <app-restore>`.

To restore in-place against a running stack (e.g. to undo a bad
migration), skip the volume restore and use `exec` against the
running container instead:

```bash
docker compose exec zulip /sbin/entrypoint.sh app:restore <filename>
```

The container will report unhealthy briefly while the in-place
restore is in progress, and returns to healthy when it completes.

## Off-site database backups

For continuous off-site database backups independent of the
volume-snapshot path, Zulip supports
[WAL-based archiving via wal-g](https://zulip.readthedocs.io/en/latest/production/export-and-import.html#wal-g), which streams
write-ahead logs to S3 for point-in-time recovery.

## See also

- {doc}`/reference/data-volume`
- {doc}`/reference/app-commands`
- {doc}`compose-upgrading`
