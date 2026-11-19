# Releasing

This repository publishes two artifacts, released separately:

- The Docker image, `ghcr.io/zulip/zulip-server`
- The Helm chart, `ghcr.io/zulip/helm-charts/zulip`

Both are published by GitHub Actions when a git tag is pushed to
`zulip/docker-zulip`; the release process in the repository itself is
a version-bump commit plus a changelog entry. See
[docs/reference/versioning.md](docs/reference/versioning.md) for how
the version numbers relate to each other.

Start with the Docker image. A chart release will reference the updated
image.

## Docker image release

Image versions are `<zulip-version>-<docker-revision>`, e.g.
`12.1-0`. The revision starts at `-0` for each new Zulip Server
release, and increments for re-packagings of the same Zulip version
(entrypoint fixes, base-image security updates, and the like).

1. Start from an up-to-date `main` with a clean working tree.

1. Write the changelog. Add a section at the top of
   [`CHANGELOG.md`](CHANGELOG.md):

   ```markdown
   ## [12.1-0] - 2026-06-26
   ```

   Review `git log <previous-tag>..HEAD` and summarize the changes
   that affect users of the image (including documentation changes);
   leave chart-only changes for the Helm chart changelog. The section
   header must match the git tag exactly: the release workflow
   extracts it (via `.github/scripts/extract-changelog.py`) to use as
   the GitHub release notes, and fails if it is missing.

1. Bump the version references:

   - `Dockerfile`: `ARG ZULIP_GIT_REF=12.1` — only when the Zulip
     Server version changes.
   - `compose.yaml`: the `zulip` service's `image:` tag. This is also
     where `docs/conf.py` reads the current version from, so the
     `ZULIP_VERSION` and `DOCKER_VERSION` substitutions and
     intersphinx links in `docs/` update automatically.
   - `README.md`: the `docker pull` example and the "Current Zulip
     version" / "Current Docker image version" lines.

   Then `git grep <old-version>` to catch stragglers. The `helm/`
   directory is expected to still reference the old image tag; it is
   updated by the chart release, not this one.

1. Commit everything as a single commit:

   ```
   Docker: Release 12.1-0.
   ```

1. Create a pull request with those changes, and merge to `main`.

1. On your local repository, pull that updated `main`.

1. Tag that commit with the bare-numeric image version and push the tag:

   ```console
   $ git tag 12.1-0
   $ git push upstream 12.1-0
   ```

1. The tag push triggers `.github/workflows/dockerfile-build.yaml`,
   which builds `linux/amd64` and `linux/arm64` images, pushes the
   multi-arch manifest to `ghcr.io/zulip/zulip-server:12.1-0`, and
   creates a GitHub release titled "Zulip Server 12.1-0" with the
   changelog section as its notes.

1. Verify: the workflow run is green, the tag appears on the
   [releases page](https://github.com/zulip/docker-zulip/releases),
   and `docker pull ghcr.io/zulip/zulip-server:12.1-0` succeeds.

## Helm chart release

Chart versions follow [Semantic Versioning](https://semver.org/),
independently of the image version; `appVersion` in `Chart.yaml`
records which image tag the chart ships by default.

1. Commit `helm: Bump Docker image to 12.1-0.` — skip this commit for a
   chart-only release. Update:

   - `helm/zulip/Chart.yaml`: `appVersion`
   - `helm/zulip/values.yaml`: `image.tag`

   Then regenerate `helm/zulip/README.md` (it embeds both values)
   and reformat it:

   ```console
   $ docker run --rm -v "$(pwd)/helm/zulip:/helm-docs" -u "$(id -u)" \
       jnorwood/helm-docs:latest
   $ npx prettier -w helm/zulip/*.md
   ```

1. Review `git log helm-<previous-version>..HEAD -- helm/zulip` to select the
   next chart version:
   - breaking changes to the chart's values API → major
   - backward-compatible features, including a new `appVersion` →
     minor
   - fixes only → patch

1. Update `version` in `helm/zulip/Chart.yaml`

1. Add a matching section at the top of
   [`helm/zulip/CHANGELOG.md`](helm/zulip/CHANGELOG.md)

1. Regenerate `helm/zulip/README.md` again:

   ```console
   $ docker run --rm -v "$(pwd)/helm/zulip:/helm-docs" -u "$(id -u)" \
       jnorwood/helm-docs:latest
   $ npx prettier -w helm/zulip/*.md
   ```

1. Commit, e.g., `helm: Release 2.1.0.` Summarize the reasoning for the version
   bump in the commit body.

1. Run the chart tests before pushing:

   ```console
   $ helm unittest helm/zulip/
   ```

1. Create a pull request with those commits, and merge to `main`.

1. On your local repository, pull that updated `main`.

1. Tag the release commit `helm-<version>` and push the tag:

   ```console
   $ git tag helm-2.1.0
   $ git push upstream helm-2.1.0
   ```

1. The tag push triggers `.github/workflows/helm-push.yaml`, which
   checks that the tag matches `version` in `Chart.yaml`, then
   packages the chart and pushes it to
   `oci://ghcr.io/zulip/helm-charts`. Chart tags do not get a GitHub
   release; `helm/zulip/CHANGELOG.md` is the record.

1. Verify: the workflow run is green, and the pushed chart reports
   the new `version` and `appVersion`:

   ```console
   $ helm show chart oci://ghcr.io/zulip/helm-charts/zulip --version 2.1.0
   ```
