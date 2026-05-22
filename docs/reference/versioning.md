# Versioning and tags

The Docker image, the Helm chart, and this repository each carry their
own version numbers. They mostly move together, but they don't have to,
and the rules for each are slightly different.

## Docker image tags

The image at `ghcr.io/zulip/zulip-server` is tagged
`<zulip-version>-<docker-revision>`. For example, `12.0-0` means
"Zulip Server 12.0, first packaging of the docker-zulip image for that
release." If we re-publish the image without a corresponding Zulip
release (for example, to pick up an Ubuntu base-image security fix),
the docker revision increments: `12.0-1`, `12.0-2`, and so on.

Every published image tag is fully pinned. We do **not** publish floating
tags such as `latest`, `12`, or `12.0`, because the most common reason
to bump a Zulip major version is a database migration that warrants
deliberate scheduling rather than landing on the next `docker compose
pull`. Treat the image tag in your `compose.yaml` (or `image.tag` in
your Helm values) as the version-of-record for your deployment. The
[GitHub releases page](https://github.com/zulip/docker-zulip/releases)
lists the available tags, and
[`CHANGELOG.md`](https://github.com/zulip/docker-zulip/blob/main/CHANGELOG.md)
is the canonical record of what changed in each release.

## Git tags in this repository

This repository carries two families of git tags, both of which exist
to drive CI rather than to be checked out by users:

- `12.0-0` — image release tags, named to match the Docker image tag.
  Pushing one publishes the corresponding image to
  `ghcr.io/zulip/zulip-server`.
- `helm-1.12.0` — Helm chart release tags. Pushing one publishes the
  chart to `ghcr.io/zulip/helm-charts/zulip`.

Image releases for the 11.5 and 11.6 series of the GHCR image used a
`ghcr-`-prefixed git tag, since at the time bare-numeric tags such as
`11.6-0` were already in use for the legacy `zulip/docker-zulip`
packaging on Docker Hub. The legacy packaging is now end-of-life, so
the prefix has been dropped: 12.x and later releases of the GHCR image
use bare-numeric git tags. Both sets of older tags remain in place for
historical reference. See
{doc}`/how-to/compose-upgrading-from-legacy` for how to migrate from
the Docker Hub packaging.

## Helm chart versions

The chart at `ghcr.io/zulip/helm-charts/zulip` carries two version
numbers, both visible in `helm/zulip/Chart.yaml`:

- `version` (e.g. `1.12.0`) is the chart's own version, in
  [Semantic Versioning](https://semver.org/) form. It increments
  whenever the chart's templates or defaults change, even if the
  underlying Zulip image is unchanged.
- `appVersion` (e.g. `12.0-0`) mirrors the Docker image tag the chart
  ships by default. It is independent of `version` because the chart's
  templates can change without a Zulip update, and an image rebuild
  can change `appVersion` without a templates change.

When upgrading, the chart `version` you select determines the
`appVersion` (and hence default image tag) that comes with it. You can
override the image tag explicitly with `image.tag` in your values file
to mix and match — for example, to take a chart-only fix on top of an
older image, or vice versa.

See
[`helm/zulip/CHANGELOG.md`](https://github.com/zulip/docker-zulip/blob/main/helm/zulip/CHANGELOG.md)
for chart release notes.

## See also

- {doc}`/how-to/compose-upgrading`
- {doc}`/how-to/helm-upgrading`
