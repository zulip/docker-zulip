# Changelog

This changelog tracks releases of the Zulip Server Docker image
published to `ghcr.io/zulip/zulip-server`. The Helm chart has its
own changelog at [helm/zulip/CHANGELOG.md](helm/zulip/CHANGELOG.md).

## [12.0-1] - 2026-05-22

- Ship `compose.override.yaml` as a tracked sample
  (`compose.override.yaml.sample`) rather than a live config file,
  so local edits no longer collide with upstream updates. Existing
  users should copy the sample to `compose.override.yaml` on
  upgrade if they don't already have one.
- Refuse `app:restore` against a live database, to prevent
  silently corrupting an in-use deployment.
- Bootstrap configuration on `app:restore` so it works against a
  fresh container, and skip the unnecessary database migration
  step during restore.
- Stop services around `app:restore` and flush memcached
  afterwards, so restored state is consistent.
- Run certbot setup as a one-shot supervisord program, making
  Let's Encrypt provisioning more reliable on container start.
- Use exec form for the Dockerfile `HEALTHCHECK` so the curl
  process is not orphaned when the check times out.
- Use canonical `/usr/bin/env` in the certbot renewal hook shebang.
- Drop the redundant `app:certs` and `app:version` commands.
- New documentation:
  - Reference pages for the `/data` volume layout, the
    entrypoint's `app:` commands, versioning and tags, and the
    ports exposed by the image.
  - How-to guide for Compose-based backups, mirroring the Helm
    persistence guide.
  - Documents the `DEBUG` environment variable, PostgreSQL
    password rotation, remapping published ports with `!override`,
    and corrected extension requirements for external PostgreSQL.
  - Restructured the everyday upgrade flow around the git tag and
    split the legacy 11.x upgrade path into its own page.

## [12.0-0] - 2026-04-27

Initial release of the new server image lineage published at
`ghcr.io/zulip/zulip-server`. High-level changes accumulated
across the 11.x series:

- Update to Zulip Server 12.0.
- Image is now published to `ghcr.io/zulip/zulip-server` with
  multi-architecture (`linux/amd64` and `linux/arm64`) manifests
  built in parallel.
- Modernized Docker Compose layout: renamed to `compose.yaml`,
  introduced `compose.override.yaml` for local settings
- Switched secret management to Docker secrets.
- Added a Dockerfile `HEALTHCHECK`.
- Reworked TLS / certificate handling: HTTP-only serving is now
  the default, and certbot issuance works again, and certificates
  are stored under `/data/certs/` so auto-generated certs can no
  longer overwrite manually-provided ones.
- Surface entrypoint and server errors via `docker logs`.
- Removed the majority of the custom-named environment variables,
  instead relying on generalized `SETTING_` and `CONFIG_` variables.
- Reworked `app:backup` and `app:restore` to use binary
  `pg_dump`s and to handle custom PostgreSQL passwords.
- Added a `manage.py` wrapper script at the repository root.
- Added a dedicated documentation site at
  [zulip.readthedocs.io/projects/docker](https://zulip.readthedocs.io/projects/docker/).
- Relocated the in-tree Helm chart from `kubernetes/chart/zulip/`
  to `helm/zulip/`, and removed the unmaintained
  `kubernetes/manual/` deployments.
