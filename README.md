# Welcome to docker-zulip!

[![](https://images.microbadger.com/badges/image/galexrt/zulip.svg)](https://microbadger.com/images/galexrt/zulip "Get your own image badge on microbadger.com")
[![Docker Repository on Quay.io](https://quay.io/repository/galexrt/zulip/status "Docker Repository on Quay.io")](https://quay.io/repository/galexrt/zulip)
[![**docker-zulip** stream](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://chat.zulip.org/#narrow/stream/backend/topic/docker)

Image available from:
* [**Quay.io**](https://quay.io/repository/galexrt/zulip)
* [**Docker Hub**](https://hub.docker.com/r/galexrt/zulip)

Current Zulip version: `1.8.1`
Current Docker image version: `1.8.1-0`

***

This is a container image for running [Zulip](https://zulip.org) in
[production](https://zulip.readthedocs.io/en/latest/production/overview.html).

**Quote from [Zulip.Org](https://zulip.org)**:
> Powerful open source group chat

[Zulip's Github](https://github.com/zulip/zulip)

***

## Zulip requirements

Zulip
[recommends at least 2GB of RAM](https://zulip.readthedocs.io/en/latest/production/requirements.html)
for running a production Zulip server.

## How to configure the container

See the
[Configuration](https://github.com/Galexrt/docker-zulip/wiki/Configuration)
page for information on configuring the container to suit your needs.

***

## How to get the container running
### To pull the image run
`docker pull quay.io/galexrt/zulip:1.8.1-0`
or
`docker pull galexrt/zulip:1.8.1-0`

### For the latest development image run
`docker pull quay.io/galexrt/zulip:dev`

***

## Configure `docker-compose.yml`

**Important: You must edit `docker-compose.yml` to provide various
settings before starting the container.**  In particular, you'll want
to set the hostname and potentially edit the default database password.

See the
[configuration documentation](https://github.com/galexrt/docker-zulip/wiki/Configuration)
to learn how to configure the image.

***

## Starting the container
To start the container, you have to use either use `docker-compose` or `kubernetes`:

**Don't forget to configure your `docker-compose.yml` properly!!**

### Using docker-compose
Change to the root of the source folder and use `docker-compose up`.

### Using Kubernetes
A Kubernetes pod file is in the `kubernetes/` folder. The command to run it would be `kubectl create -f ./kubernetes/`.

***

## Creating an organization

This step is the analog of
[creating an organization in Zulip](https://zulip.readthedocs.io/en/latest/production/install.html#step-3-create-a-zulip-organization-and-log-in)
in the main Zulip documentation.  To generate the one-time use link,
you can use the following command:

```bash
docker-compose exec zulip sudo -H -u zulip -g zulip /home/zulip/deployments/current/manage.py generate_realm_creation_link
```

Follow the link you just got printed and follow the instructions to
create your new organization (and first administrator account).

***

## Troubleshooting
### zulip-django exited
The main reason for this to happen is that you are missing a config file named `uwsgi.ini`.
The get this file run:
```
// This command copy the output of file uwsgi.ini into your data volume on the host.
// Replace `YOUR_ZULIP_DATA_PATH` with your path.
host$ docker run --rm quay.io/galexrt/zulip:1.5.2 cat /etc/zulip/uwsgi.ini > YOUR_ZULIP_DATA_PATH/settings/etc-zulip/uwsgi.ini
```

## Community

Chat with other docker-zulip users on the
[chat.zulip.org](https://chat.zulip.org/). The stream/channel is
[#production-help](https://chat.zulip.org/#narrow/stream/31-production-help).

## Contributing

If you find this container useful, here's how you can help:

* Help users with issues they may encounter
* Send a pull request with your awesome new features and bug fixes

_Please use 4 spaces as intent in the files, Thanks!_

**A big thanks to everybody that sends in issues, pull request!** and helps with the issues/tickets! **:-)**
