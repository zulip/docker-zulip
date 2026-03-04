# Building custom Zulip images for Docker Compose

## Running custom scripts on startup

The Docker image will execute all executable scripts found in
`/data/post-setup.d/`. You can bind mount this directory from the host to
perform additional steps when the image boots:

```yaml
services:
  zulip:
    volumes:
      - "./post-setup.d/:/data/post-setup.d/:ro"
```

The image does not need to be rebuilt when using post-setup scripts; this is the
most light-weight form of customization.

## Rebuilding the Docker image

You can build a the Docker image from scratch by running:

```bash
docker compose build zulip
```

To customize the branch, tag, or repository URL (for example, if you have [forked
Zulip to make local modifications][local-changes]), adjust your
`compose.override.yaml`:

[local-changes]: https://zulip.readthedocs.io/en/stable/production/modify.html

```yaml
services:
  zulip:
    build:
      args:
        ZULIP_GIT_URL: https://github.com/example-username/zulip.git
        ZULIP_GIT_REF: example-branch-name
```

## Per-file overrides

As a shortcut to making changes in a repository, files under the
`custom_zulip_files/` directory are layered on top of the Git checkout before
building.

As an example, if you want to test a change to
`scripts/setup/generate-self-signed-cert`, you would grab a copy of
the script from zulip/zulip, place it at
`custom_zulip_files/scripts/setup/generate-self-signed-cert`, make
your local edits, and then run `docker compose build zulip`.

## See also

- [Compose Build specification](https://docs.docker.com/reference/compose-file/build/)
- {doc}`/reference/environment-vars`
