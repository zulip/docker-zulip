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

## Backup considerations

The `app:backup` command (and the cron job driven by
{ref}`auto-backup-enabled` / {ref}`auto-backup-interval`) writes
PostgreSQL dumps to `/data/backups/`, but a full backup of the
deployment includes everything else under `/data` as well —
particularly `/data/uploads/` (when the local upload backend is in
use), `/data/etc-zulip/` (under `LINK_SETTINGS_TO_DATA`) or
`/data/zulip-secrets.conf` (otherwise), and the certificates.

To back up the entire volume rather than just the database, see the
volume-snapshot command in {doc}`/how-to/compose-upgrading` or
{doc}`/how-to/helm-persistence`. To avoid backing up uploads at all,
configure Zulip to use {doc}`S3-compatible storage
<zulip:production/upload-backends>` instead.

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
