# Using the Zulip Docker Compose repository

## Understanding Docker

Docker and other container systems are built around shareable container
images. An image is a read-only template with instructions for creating a
container.

Often, an image is based on another image, with a bit of additional
customization. For example, Zulip's `zulip-postgresql` image extends the
standard `postgresql` image (by installing a couple `postgres`
extensions). Meanwhile, the `zulip` image is built on top of a standard `ubuntu`
image, adding all the code for a Zulip application/web server.

Every time you boot a container based on a given image, it's like booting off a
CD-ROM: you get the exact same image (and anything written to the image's
filesystem is lost). To handle persistent state that needs to persist after the
Docker equivalent of a reboot or upgrades (like uploaded files or the Zulip
database), container systems let you configure certain directories inside the
container from the host.

## Volumes

This project's `docker-compose.yml` configuration file uses [Docker managed
volumes][volumes] to store [persistent Zulip data][persistent-data]. If you use
the Docker Compose deployment, you should make sure that Zulip's volumes are
backed up, to ensure that Zulip's data is backed up.

[volumes]: https://docs.docker.com/engine/storage/volumes/
[persistent-data]: https://zulip.readthedocs.io/en/latest/production/export-and-import.html#backups

## Configuration

While it is possible to configure the project using files on disk, as in a
standard Zulip deployment, most Docker deployments use [environment
variables][env-vars] to tell the container how to configure itself. All of the
{doc}`standard Zulip settings <zulip:production/settings>` and
{doc}`system configuration options <zulip:production/system-configuration>`
are available via environment variables.

[env-vars]: https://docs.docker.com/compose/how-tos/environment-variables/

## Secrets

Zulip's Docker container uses [Docker secrets][secrets] to synchronize secrets
between services, as well as within Zulip itself. Secrets are not stored in the
Docker Compose configuration, but are instead stored in one or more adjacent
files. This keeps the configuration separate from sensitive information, and
makes them easier to provide to both sides of a secured connection.

[secrets]: https://docs.docker.com/compose/how-tos/use-secrets/

## Dependencies

This project defines a Docker image for a Zulip server, as well as sample
configuration to run that Zulip server with each of the major
{doc}`services that Zulip uses <zulip:overview/architecture-overview>` in
its own container: `redis`, `postgres`, `rabbitmq`, `memcached`.

## See also

- [How Docker Compose works](https://docs.docker.com/compose/intro/compose-application-model/)
- {doc}`/how-to/compose-getting-started`
- {doc}`/how-to/compose-secrets`
- {doc}`/how-to/compose-settings`
