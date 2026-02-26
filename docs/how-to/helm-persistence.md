# Helm: Storage and backups

Zulip stores persistent data (uploads, avatars, and configuration) in a volume
mounted at `/data` inside the container. The Helm chart manages this storage
through a PersistentVolumeClaim.

## Configuring storage

By default, the chart creates a 10Gi PVC with `ReadWriteOnce` access. You can
customize this in your values file:

```yaml
zulip:
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    size: 20Gi
    storageClass: "fast-ssd"
```

## Using an existing PVC

If you have a pre-existing PersistentVolumeClaim (for example, restored from a
backup), you can tell the chart to use it instead of creating a new one:

```yaml
zulip:
  persistence:
    enabled: true
    existingClaim: my-existing-zulip-pvc
```

When `existingClaim` is set, the chart does not create a PVC; the StatefulSet
references the named claim directly.

## Backing up

Zulip's database backup command creates a backup in `/data/backups/`:

```bash
kubectl exec zulip-0 -c zulip -- \
    /sbin/entrypoint.sh app:backup
```

To copy the backup to your local machine:

```bash
kubectl cp zulip-0:/data/backups/ ./backups/ -c zulip
```

Note that these backups contain _only_ the database. If you use the default
local upload backend, user-uploaded files (stored in `/data/uploads/`) must be
backed up separately. Alternatively, Zulip supports
[S3-compatible storage](inv:zulip:*#production/upload-backends) as a native
upload backend, which avoids the need to back up local uploads entirely.

## Off-site database backups

For continuous off-site database backups, Zulip supports
[WAL-based archiving via wal-g](inv:zulip:*#production/export-and-import),
which streams write-ahead logs to S3 for point-in-time recovery.

## Adding a sidecar container

You can use the `sidecars` value to run additional containers alongside Zulip
that share its persistent volume. The volume name follows the pattern
`<fullname>-persistent-storage`; for the `helm install zulip .` command from the
getting-started guide, the full name resolves to `zulip`, so the volume is
`zulip-persistent-storage`:

```yaml
sidecars:
  - name: my-sidecar
    image: busybox:latest
    command: ["sleep", "infinity"]
    volumeMounts:
      - name: zulip-persistent-storage
        mountPath: /data
        readOnly: true
```

## See also

- {doc}`helm-upgrading`
- {doc}`helm-commands`
