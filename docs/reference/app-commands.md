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

```{important}
This command backs up only the PostgreSQL database. Uploaded files
(in `/data/uploads/` when the local upload backend is in use),
configuration in `/data/etc-zulip/`, and `zulip-secrets.conf` are
**not** included. For a complete backup that captures all of those,
see Zulip's {doc}`zulip:production/export-and-import`.
```

When `AUTO_BACKUP_ENABLED` is left at its default, this same command
runs on the schedule set by `AUTO_BACKUP_INTERVAL`; see
{ref}`auto-backup-enabled` and {ref}`auto-backup-interval`.

## `app:restore`

Restores a database from a `pg_dump` archive produced by `app:backup`:

```bash
docker compose exec zulip /sbin/entrypoint.sh app:restore <filename>
```

`<filename>` is the basename of a file in `$DATA_DIR/backups/`. If
omitted, the command prompts interactively. Restore drops and
recreates existing tables (`pg_restore --clean --if-exists`); a
10-second countdown precedes the destructive phase so it can be
aborted with Ctrl-C.

```{important}
As with `app:backup`, this command restores only the database. It
does not restore uploads, configuration, or secrets, and it cannot
be used to migrate from a Zulip export archive. For those, see
{doc}`zulip:production/export-and-import`.
```

## `app:help`

Prints the list of available commands and exits. Also runs as a
fallback if the entrypoint receives an argument it doesn't recognize.

## See also

- {doc}`/how-to/compose-commands`
- {doc}`/how-to/helm-commands`
- {doc}`/how-to/compose-getting-started`
