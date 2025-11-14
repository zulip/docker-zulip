# Docker

`docker-zulip` is the official Docker container image for running a [Zulip
server](https://zulip.com/) in [production][prod-install]. Built images are
available from [Docker Hub][docker-hub].

[prod-install]: https://zulip.readthedocs.io/en/latest/production/install.html
[docker-hub]: https://hub.docker.com/r/zulip/docker-zulip

```console
$ docker pull zulip/docker-zulip:latest
```

:Current Docker image version: **{{ DOCKER_VERSION }}**
:Current Helm chart version: **{{ HELM_VERSION }}**

We recommend using the Docker image if your organization has a
preference for deploying services using Docker. Deploying with Docker
moderately increases the effort required to install, maintain, and
upgrade a Zulip installation, compared with the [standard Zulip
installer][normal-install].

[normal-install]: https://zulip.readthedocs.io/en/latest/production/install.html

## Troubleshooting

Common issues include:

- Invalid configuration resulting in the `zulip` container not starting; check
  `docker compose ps` to see if it started, and then read the logs for the Zulip
  container to see why it failed.
- A new Zulip setting not being passed through the Docker `entrypoint.sh` script
  properly. If you run into this sort of problem you can work around it by
  specifying a `ZULIP_CUSTOM_SETTINGS` with one setting per line below, but
  please report an issue so that we can fix this for everyone else.

## Community support

You can get community support and tell the developers about your
experiences using this project on
[#production-help](https://chat.zulip.org/#narrow/stream/31-production-help) on
[chat.zulip.org](https://chat.zulip.org/), the Zulip community server.

## Contributing

We love community contributions, and respond quickly to issues and
PRs. Some particularly useful ways to contribute right now are:

- Contribute to this documentation by opening issues about what
  confused you or submitting pull requests!
- Reporting bugs or rough edges!

## Credits

Huge thanks to everyone who has contributed. Special thanks to
[Alexander Trost](https://github.com/galexrt/), who created
`docker-zulip` and did a huge amount of the early work required to
make a high-quality Docker image for Zulip possible.

```{toctree}
environment
manual-configuration
compose
helm
upgrading
incoming-email
reverse-proxies
outgoing-proxy
high-availability
```
