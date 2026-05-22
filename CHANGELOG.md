# Changelog

This changelog tracks releases of the Zulip Server Docker image
published to `ghcr.io/zulip/zulip-server`. The Helm chart has its
own changelog at [helm/zulip/CHANGELOG.md](helm/zulip/CHANGELOG.md).

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
