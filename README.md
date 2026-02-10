# Zulip Docker image overview

[![**docker** topic in **production-help** channel](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://chat.zulip.org/#narrow/channel/31-production-help/topic/docker)

This is the official Docker container image for running a [Zulip
server](https://zulip.com) in production. Built images are
available from [ghcr.io](https://ghcr.io/zulip/zulip-server):

```console
$ docker pull ghcr.io/zulip/zulip-server:11.5-0
```

Current Zulip version: `11.5`
Current Docker image version: `11.5-0`

> [!NOTE]
> A previous packaging of Zulip for Docker still exists on Docker Hub, as
> [zulip/docker-zulip](https://hub.docker.com/r/zulip/docker-zulip). That version
> will continue to be supported through the end of the Zulip Server 11.x series.
> See the [upgrade steps][upgrade].

We recommend using the Docker image if your organization has a
preference for deploying services using Docker. Deploying with Docker
moderately increases the effort required to install, maintain, and
upgrade a Zulip installation, compared with the [standard Zulip
installer][normal-install].

[upgrade]: https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-upgrading.html#upgrading-from-zulip-docker-zulip-11-x-and-earlier
[normal-install]: https://zulip.readthedocs.io/en/latest/production/install.html
[zulip-architecture]: https://zulip.readthedocs.io/en/latest/overview/architecture-overview.html

## Prerequisites

To use this image, you need the following:

- An installation of [Docker][install-docker] and [Docker
  Compose][install-docker-compose], or a [Kubernetes][k8s] runtime engine.
- We [recommend at least 2GB of available RAM][prod-requirements] for running a
  production Zulip server; you'll want 4GB if you're building the container
  (rather than using the pre-built images). If you're just testing and/or aren't
  expecting a lot of users/messages, you can get away with significantly less
  especially for the `postgres`, `memcached`, etc. containers, because Docker
  makes it easy to sharply limit the RAM allocated to the services Zulip depends
  on, like Redis, memcached, and PostgreSQL (at the cost of potential
  performance issues).

This project doesn't support `docker-rootless` or `uDocker`; Zulip needs root
access to set properties like the maximum number of open file descriptions via
`ulimit` (which is important for it to handle thousands of connected clients).

[install-docker]: https://docs.docker.com/install/
[install-docker-compose]: https://docs.docker.com/compose/install/
[k8s]: https://kubernetes.io/
[prod-requirements]: https://zulip.readthedocs.io/en/latest/production/requirements.html

## Documentation

See our [main documentation][docker-zulip-docs].

[docker-zulip-docs]: https://zulip.readthedocs.io/projects/docker/
