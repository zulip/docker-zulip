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
    accessModes:
      - ReadWriteOnce
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

(helm-volume-snapshot)=

## Backing up

The PVC mounted at `/data` is the unit of backup. A
[`VolumeSnapshot`](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
captures everything Zulip needs to restore a deployment, because
`/data/backups/` already holds a recent `pg_dump` written there by
`app:backup` on a daily schedule (see {ref}`auto-backup-enabled`).

Most operators drive snapshot creation through a higher-level
orchestrator that handles retention, off-cluster storage, and
scheduling. [Velero](https://velero.io/) is the standard open-source
option, and commercial alternatives also exist. The `VolumeSnapshot`
CRD is also usable directly when no orchestrator is in play.

For coherence with the freshest possible database dump, refresh
`app:backup` immediately before snapshotting:

```bash
kubectl exec zulip-0 -c zulip -- /sbin/entrypoint.sh app:backup
```

If you need just the database dump out-of-band:

```bash
kubectl cp zulip-0:/data/backups/ ./backups/ -c zulip
```

To avoid backing up uploads at all, configure Zulip to use
[S3-compatible storage](https://zulip.readthedocs.io/en/latest/production/upload-backends.html#s3-backend) as a
native upload backend, which keeps the PVC small.

See {doc}`/reference/data-volume` for the cross-deployment backup
model.

## Off-site database backups

For continuous off-site database backups, independent of the
volume-snapshot path, Zulip supports
[WAL-based archiving via wal-g](https://zulip.readthedocs.io/en/latest/production/export-and-import.html#wal-g),
which streams write-ahead logs to S3 for point-in-time recovery.

## Adding a sidecar container

You can use the `sidecars` value to run additional containers alongside Zulip
that share its persistent volume. The volume name follows the pattern
`<fullname>-persistent-storage`; for the `helm install zulip` command from the
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
- {doc}`/reference/app-commands`
- {doc}`/reference/data-volume`
