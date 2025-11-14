# Docker Compose

## The Docker data storage model

Docker and other container systems are built around shareable
container images. An image is a read-only template with instructions
for creating a container.

Often, an image is based on another image, with a bit of additional
customization. For example, Zulip's `zulip-postgresql` image extends
the standard `postgresql` image (by installing a couple `postgres`
extensions). Meanwhile, the `zulip` image is built on top of a
standard `ubuntu` image, adding all the code for a Zulip
application/web server.

Every time you boot a container based on a given image, it's like
booting off a CD-ROM: you get the exact same image (and anything
written to the image's filesystem is lost). To handle persistent
state that needs to persist after the Docker equivalent of a reboot or
upgrades (like uploaded files or the Zulip database), container
systems let you configure certain directories inside the container
from the host.

This project's `docker-compose.yml` configuration file uses [Docker
managed volumes][volumes] to store [persistent Zulip
data][persistent-data]. If you use the Docker Compose deployment, you
should make sure that Zulip's volumes are backed up, to ensure that
Zulip's data is backed up.

This project defines a Docker image for a Zulip server, as well as
sample configuration to run that Zulip server with each of the major
[services that Zulip uses][zulip-architecture] in its own container:
`redis`, `postgres`, `rabbitmq`, `memcached`.

[volumes]: https://docs.docker.com/engine/storage/volumes/
[persistent-data]: https://zulip.readthedocs.io/en/latest/production/export-and-import.html#backups

## Starting the server

You can boot your Zulip installation with:

```
docker compose pull
docker compose up
```

This will boot the 5 containers declared in `docker-compose.yml`. The
`docker compose` command will print a bunch of output, and then
eventually hang once everything is happily booted, usually ending with
a bunch of lines like this:

```
rabbitmq_1   | =INFO REPORT==== 27-May-2018::23:26:58 ===
rabbitmq_1   | accepting AMQP connection <0.534.0> (172.18.0.3:49504
-> 172.18.0.5:5672)
```

You can inspect what containers are running in another shell with
`docker compose ps` (remember to `cd` into the `docker-zulip`
directory first).

If you hit `Ctrl-C`, that will stop your Zulip server cluster. If
you'd prefer to have the containers run in the background, you can use
`docker compose up -d`.

If you want to build the Zulip image yourself, you can do that by
running `docker compose build`; see also
[the documentation on building a custom Git version version](upgrading.md#upgrading-from-a-git-repository).

## Creating your organization

You can now follow the normal Zulip installer instructions for how to
[create a Zulip organization and log in][create-organization] to your
new Zulip server. You'll generate the realm creation link as follows:

```bash
docker compose exec -u zulip zulip \
    /home/zulip/deployments/current/manage.py generate_realm_creation_link
```

But don't forget to review the [getting started][next-steps] links at
the end of the main installation guide.

[next-steps]: https://zulip.readthedocs.io/en/latest/production/install.html#getting-started-with-zulip

## Connecting to your Zulip server

You can now connect to your Zulip server. For example, if you set
this up on a laptop with the default port mappings and
`SETTING_EXTERNAL_HOST`, typing `http://localhost/` will take you to
your server. Note that in this default scenario, (1) you'll have to
proceed past a self-signed SSL error, and (2) you won't be able to
login until you create an organization, but visiting the URL is a good
way to confirm that your networking configuration is working
correctly.

## Running management commands

```bash
docker compose exec -it zulip bash
```

```bash
# Run a Zulip management command
docker compose exec -u zulip zulip \
    /home/zulip/deployments/current/manage.py list_realms
```

```bash
#!/bin/sh

docker compose exec -u zulip zulip /home/zulip/deployments/current/manage.py "$@"
```
