# Zulip Docker image overview

[![](https://images.microbadger.com/badges/image/zulip/docker-zulip.svg)](https://microbadger.com/images/zulip/docker-zulip "Get your own image badge on microbadger.com") [![**docker-zulip** stream](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://chat.zulip.org/#narrow/stream/backend/topic/docker)

`docker-zulip` is the official Docker container image for running a
[Zulip server](https://zulip.com) in
[production][prod-overview]. Built images are available from: [Docker
Hub](https://hub.docker.com/r/zulip/docker-zulip):

[zulip-architecture]: https://zulip.readthedocs.io/en/latest/overview/architecture-overview.html

## Prerequisites

To use `docker-zulip`, you need the following:

- An installation of [Docker][install-docker] and [Docker
  Compose][install-docker-compose] or a [Kubernetes][k8s] runtime engine.
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

## Documentation

See our [main documentation][docker-zulip-docs].

[install-docker]: https://docs.docker.com/install/
[install-docker-compose]: https://docs.docker.com/compose/install/
[k8s]: https://kubernetes.io/
[prod-requirements]: https://zulip.readthedocs.io/en/latest/production/requirements.html
[docker-zulip-docs]: https://docker-zulip.readthedocs.io/
