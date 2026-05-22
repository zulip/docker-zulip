# Helm: Upgrading

You can upgrade your Zulip installation by updating the chart's image tag
and running `helm upgrade`. When the upgraded container boots, it will
automatically run the necessary database migrations.

## Upgrading the Zulip version

1. Check the {doc}`Zulip upgrade notes <zulip:overview/changelog>`
   for any breaking changes in the target version.

1. (Optional) Back up your data before upgrading; see {doc}`helm-persistence`.

1. Update the image tag in your values file:

   ```yaml
   image:
     tag: "{{ DOCKER_VERSION }}"
   ```

   Or pass it on the command line:

   ```bash
   helm upgrade zulip oci://ghcr.io/zulip/helm-charts/zulip \
       -f values-local.yaml --set image.tag={{ DOCKER_VERSION }}
   ```

1. Wait for the pod to restart and become ready:

   ```bash
   kubectl rollout status statefulset/zulip
   ```

## Upgrading the chart version

Upgrade to a newer chart version by specifying the target `--version`:

```bash
helm upgrade zulip oci://ghcr.io/zulip/helm-charts/zulip \
    --version <new-version> -f values-local.yaml
```

## Upgrading from chart 1.x to 2.0

Chart 2.0 reshapes several values keys to match the Bitnami
subcharts' own API and to align with broader Helm conventions.
Update your `values-local.yaml` (and any CI / GitOps copies) before
upgrading:

| Old key                              | New key                                                       |
| ------------------------------------ | ------------------------------------------------------------- |
| `postgresql.auth.postgresqlPassword` | `postgresql.auth.postgresPassword`                            |
| `memcached.memcachedUsername`        | `memcached.auth.username`                                     |
| `memcached.memcachedPassword`        | `memcached.auth.password`                                     |
| `zulip.persistence.accessMode` (str) | `zulip.persistence.accessModes` (list)                        |
| `zulip.password`                     | `zulip.environment.SECRETS_secret_key` (supports `valueFrom`) |
| `statefulSetLabels`                  | `commonLabels` (applied to every chart resource)              |

Two of these were silent footguns in chart 1.x:
`postgresql.auth.postgresqlPassword` was ignored by Bitnami's
PostgreSQL subchart (the admin password was random), and the
`memcached.memcachedPassword` flow left the memcached server with
SASL disabled. Installs that copied the chart's own examples were
running unauthenticated against memcached and with a random
PostgreSQL admin password. Confirm the new keys are set before
upgrading.

The 1.x default of `TRUST_GATEWAY_IP: true` was also removed; if
your installation relied on the gateway IP to trust Ingress traffic,
configure `zulip.environment.LOADBALANCER_IPS` instead. See
{doc}`helm-proxy-trust`.

## See also

- {doc}`helm-persistence`
- {doc}`helm-commands`
- {doc}`/reference/versioning`
