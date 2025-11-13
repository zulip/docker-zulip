# Compose: Running commands

Once the container is running, you can run commands in the Zulip container using
`docker compose exec`. For example, to get a terminal within the container:

```bash
docker compose exec zulip bash
```

## Running management commands

Some parts of the Zulip documentation may reference running {doc}`management commands <zulip:production/management-commands>`. These can also be run via
`docker compose exec`, with and additional `-u zulip` to run as the `zulip`
user:

```bash
# Run a Zulip management command
docker compose exec -u zulip zulip \
    /home/zulip/deployments/current/manage.py list_realms
```

We provide a helper `manage.py` in the repository file to make this simpler:

```bash
# In the docker-zulip directory:
./manage.py list_realms
```

## See also

- [`docker compose exec` reference](https://docs.docker.com/reference/cli/docker/compose/exec/)
- {doc}`zulip:production/management-commands`
