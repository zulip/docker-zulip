# `/data` volume layout

Zulip's container persists state under `/data` (set via the
`DATA_DIR` environment variable in the Dockerfile). The Compose
deployment mounts this from a named Docker volume; the Helm chart
mounts it from a PersistentVolumeClaim. Either way the layout is the
same.

## Top-level structure

| Path                       | Purpose                                                                                                     | Created by                   |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `/data/backups/`           | Database dumps from {doc}`app:backup <app-commands>` and the auto-backup cron job                           | First boot                   |
| `/data/uploads/`           | User-uploaded files (avatars, attachments) when the local upload backend is in use                          | First boot                   |
| `/data/certs/self-signed/` | Self-signed certificate and key when `CERTIFICATES=self-signed`                                             | The cert configuration phase |
| `/data/certs/letsencrypt/` | Let's Encrypt account, certificate, and renewal config when `CERTIFICATES=certbot`                          | The cert configuration phase |
| `/data/certs/manual/`      | Operator-supplied certificate (`zulip.combined-chain.crt`) and key (`zulip.key`) when `CERTIFICATES=manual` | Operator                     |
| `/data/etc-zulip/`         | Mirror of `/etc/zulip/` (settings, secrets) when {ref}`link-settings-to-data` is set                        | First boot, if enabled       |
| `/data/zulip-secrets.conf` | `zulip-secrets.conf` when {ref}`link-settings-to-data` is _not_ set; symlinked into `/etc/zulip/`           | First boot                   |
| `/data/post-setup.d/`      | Operator-supplied scripts run after each boot's setup phase, see {ref}`zulip-run-post-setup-scripts`        | Operator                     |

## Backup model

The `/data` volume is the unit of backup: a snapshot of it captures
everything Zulip needs to restore a deployment. That works because
`/data/backups/` already holds a recent `pg_dump` written there by
{doc}`app-commands`'s `app:backup` command. By default `app:backup`
runs daily via the {ref}`auto-backup-enabled` cron job, so a `/data`
snapshot taken at any time includes a database state from at most one
{ref}`auto-backup-interval` ago, alongside the uploads, certificates,
and configuration also living under `/data`.

The live PostgreSQL data directory lives in a separate volume
(`postgresql-14` in the Compose deployment) and is _not_ safe to
snapshot directly while the database is running; the `app:backup`
artifact is the consistent, restorable form.

To get the freshest possible database state in the snapshot, refresh
`app:backup` immediately before snapshotting. See
{doc}`/how-to/compose-backups` or {doc}`/how-to/helm-persistence` for
the per-deployment recipes.

### Avoiding upload backups

Configuring Zulip to use
[S3-compatible storage](https://zulip.readthedocs.io/en/latest/production/upload-backends.html#s3-backend) keeps
user uploads out of the PVC entirely, shrinking the snapshot footprint
and letting snapshot retention focus on configuration and database
state.

## Sizing

The dominant contributors to disk usage on a busy server are usually
`/data/uploads/` (user attachments) and `/data/backups/` (one dump
per `AUTO_BACKUP_INTERVAL` cycle, kept indefinitely). Operators
running with the local upload backend should plan PVC / volume size
around expected upload volume; those using the S3 backend can size
the volume much smaller.

## See also

- {doc}`environment-vars`
- {doc}`app-commands`
- {doc}`/how-to/compose-upgrading`
- {doc}`/how-to/helm-persistence`
