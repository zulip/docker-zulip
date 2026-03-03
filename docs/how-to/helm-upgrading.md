# Helm: Upgrading

You can upgrade your Zulip installation by updating the chart's image tag
and running `helm upgrade`. When the upgraded container boots, it will
automatically run the necessary database migrations.

## Upgrading the Zulip version

1. Check the [Zulip upgrade notes](https://zulip.readthedocs.io/en/latest/overview/changelog.html)
   for any breaking changes in the target version.

1. (Optional) Back up your data before upgrading; see {doc}`helm-persistence`.

1. Update the image tag in your values file:

   ```yaml
   image:
     tag: "11.5-2"
   ```

   Or pass it on the command line:

   ```bash
   helm upgrade zulip oci://ghcr.io/zulip/helm-charts/zulip \
       -f values-local.yaml --set image.tag=11.5-2
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

## See also

- {doc}`helm-persistence`
- {doc}`helm-commands`
