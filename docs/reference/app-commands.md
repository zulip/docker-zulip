# `app:` commands in the Docker image

The image's `entrypoint.sh` recognizes a small set of `app:`-prefixed
commands that wrap common operational tasks. They're invoked by
passing the command name as the container's argument, either via
`docker compose run` for a one-shot ephemeral container, or via
`docker compose exec` against an already-running one.

## `app:run`

Runs the Zulip server. This is the default command set in the
Dockerfile; you don't normally need to type it. It performs the same
initial-configuration work as `app:init`, then starts supervisord to
manage Zulip's processes.

## `app:init`

Performs first-boot validation and database setup, but does **not**
start the long-running server. Use it before the first
`docker compose up` to confirm the configuration parses, that the
database is reachable, and that schema migrations succeed:

```bash
docker compose run --rm zulip app:init
```

A clean run ends with `=== End Initial Configuration Phase ===`.
See {doc}`/how-to/compose-getting-started`.

## `app:managepy`

Wraps a `manage.py` invocation. The most common use is on an
ephemeral container when the `zulip` service isn't running:

```bash
docker compose run --rm zulip app:managepy <subcommand> [args...]
```

When the `zulip` service is running, prefer `docker compose exec`
directly (see {doc}`/how-to/compose-commands`); it avoids spinning up
a fresh container per invocation.

## `app:backup`

Runs `pg_dump` against the configured PostgreSQL host and writes a
timestamped dump to `$DATA_DIR/backups/`:

```bash
docker compose exec zulip /sbin/entrypoint.sh app:backup
```

This command's output is the database half of a complete backup: a
snapshot of the `/data` volume captures both the dump it just wrote
and the rest of the deployment's persistent state (uploads,
configuration, certificates, secrets). See
{doc}`/reference/data-volume` for the full backup model and the
volume-snapshot recipes.

`app:backup` runs on a daily schedule by default via
{ref}`auto-backup-enabled` and {ref}`auto-backup-interval`, so the
`/data` volume always contains a recent dump for a snapshot to pick
up.

(app-restore)=

## `app:restore`

Restores a database from a `pg_dump` archive produced by `app:backup`:

```bash
docker compose exec zulip /sbin/entrypoint.sh app:restore <filename>
```

`<filename>` is the basename of a file in `$DATA_DIR/backups/`. If
omitted, the command prompts interactively. Restore drops and
recreates existing tables (`pg_restore --clean --if-exists`); a
10-second countdown precedes the destructive phase so it can be
aborted with Ctrl-C. The Zulip application server is stopped around
the restore and memcached is flushed afterwards.

To restore the rest of a deployment alongside the database, restore
the `/data` volume from a snapshot first; the dump file `app:restore`
consumes is one of the files inside that volume. See
{doc}`/reference/data-volume`. To migrate from a Zulip export archive
(a different tool with different semantics), see
{doc}`zulip:production/export-and-import`.

When run from a one-shot container (e.g. `docker compose run --rm
zulip app:restore <file>`), `app:restore` refuses to proceed if any
other process is connected to the target database, since those
connections are most likely live Zulip workers in a sibling
container that would be left with stale state. Stop the running
stack (`docker compose down`) before invoking the one-shot form, or
set `FORCE_RESTORE=True` to override the check.

## `app:help`

Prints the list of available commands and exits. Also runs as a
fallback if the entrypoint receives an argument it doesn't recognize.

## See also

- {doc}`/how-to/compose-commands`
- {doc}`/how-to/helm-commands`
- {doc}`/how-to/compose-getting-started`
