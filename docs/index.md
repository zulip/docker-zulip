# Docker

This is the official Docker container image for running a [Zulip
server](https://zulip.com/) in production. Built images are
available from [ghcr.io](https://ghcr.io/zulip/zulip-server):

```console
$ docker pull ghcr.io/zulip/zulip-server:11.5-2
```

:Current Zulip version: **{{ ZULIP_VERSION }}**
:Current Docker image version: **{{ DOCKER_VERSION }}**
:Current Helm chart version: **{{ HELM_VERSION }}**

:::{note}
A previous packaging of Zulip for Docker still exists on Docker Hub, as
[zulip/docker-zulip](https://hub.docker.com/r/zulip/docker-zulip). That version
will continue to be supported through the end of the Zulip Server 11.x series.
See the [details on how to upgrade to the new image][upgrade].

This documentation is only for the new `ghcr.io/zulip/zulip-server` image.
Documentation for the previous image can be found [here][docker-hub-docs].
:::

We recommend using the Docker image if your organization has a preference for
deploying services using Docker. Deploying with Docker moderately increases the
effort required to install, maintain, and upgrade a Zulip installation, compared
with the [standard Zulip installer][normal-install].

[upgrade]: how-to/compose-upgrading.md#upgrading-from-zulipdocker-zulip-11x-and-earlier
[docker-hub-docs]: https://github.com/zulip/docker-zulip/blob/11.x/README.md
[normal-install]: https://zulip.readthedocs.io/en/latest/production/install.html

## Docker runtime support

We provide a Docker image, along with both [`docker compose`][docker-compose]
configuration and [Helm charts][]. If you are new to Docker, we suggest starting
with `docker compose`; see our [Docker Compose manual](manual/docker-compose.md)
for background, and our [Docker Compose getting started
how-to](how-to/compose-getting-started.md).

We do not support `docker-rootless` or `uDocker`; Zulip needs root access to set
properties like the maximum number of open file descriptions via `ulimit` (which
is important for it to handle thousands of connected clients).

[docker-compose]: https://docs.docker.com/compose/
[helm charts]: https://helm.sh/docs/topics/charts/

## Scaling out and high availability

This image is not designed to make it easy to run multiple copies of the `zulip`
application server container (and you need to know a lot about Zulip to do this
sort of thing successfully). If you're interested in running a high-availability
Zulip installation, your best bet is to get in touch with the Zulip team at
`sales@zulip.com`.

## Community support

You can get community support and tell the developers about your experiences
using this project on
[#production-help](https://chat.zulip.org/#narrow/stream/31-production-help) on
[the chat.zulip.org development
community](https://zulip.com/development-community/). Please be sure to mention
that you are using the Docker install.

## Credits

Huge thanks to everyone who has contributed. Special thanks to [Alexander
Trost](https://github.com/galexrt/), who created `docker-zulip` and did a huge
amount of the early work required to make a high-quality Docker image for Zulip
possible.

## Contents

```{toctree}
---
maxdepth: 3
---

manual/index
how-to/compose-index
reference/index
```
