# Welcome to docker-zulip!

[![](https://images.microbadger.com/badges/image/galexrt/zulip.svg)](https://microbadger.com/images/galexrt/zulip "Get your own image badge on microbadger.com")
[![Docker Repository on Quay.io](https://quay.io/repository/galexrt/zulip/status "Docker Repository on Quay.io")](https://quay.io/repository/galexrt/zulip)
[![**docker-zulip** stream](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://chat.zulip.org/#narrow/stream/backend/topic/docker)

This is a container image for running [Zulip](https://zulipchat.com)
([Github](https://github.com/zulip/zulip)) in
[production][prod-overview]. Image available from:

* [**Quay.io**](https://quay.io/repository/galexrt/zulip) (`docker pull quay.io/galexrt/zulip:1.8.1-0`)
* [**Docker Hub**](https://hub.docker.com/r/galexrt/zulip) (`docker pull galexrt/zulip:1.8.1-0`)

Current Zulip version: `1.8.1`
Current Docker image version: `1.8.1-0`

## Overview

This project defines a Docker image for a Zulip server, as well as
sample configuration to run that Zulip web/application server with
each of the major [services that Zulip uses][zulip-architecture] in
its own container: `redis`, `postgres`, `rabbitmq`, `memcached`.

We have configuration and documentation for
[Docker Compose](#running-a-zulip-server-with-docker-compose) and
[Kubernetes](#running-a-zulip-server-with-kubernetes); contributions are welcome for
documenting other container runtimes and flows.

If you aren't already a Docker expert, we recommend starting by
reading our brief overview of how Docker and containers work in the
next section.

[zulip-architecture]: https://zulip.readthedocs.io/en/latest/overview/architecture-overview.html

### The Docker data storage model

Docker and other container systems are built around shareable
container images.  An image is a read-only template with instructions
for creating a container.  Often, an image is based on another image,
with a bit of additional customization.  For example, Zulip's
`zulip-postgresql` image extends the standard `postgresql` image (by
installing a couple `postgres` extensions).  And the `zulip` image is
built on top of a standard `ubuntu` image, adding all the code for a Zulip
application/web server.

Every time you boot a container based on a given image, it's like
booting off a CD-ROM: you get the exact same image (and anything
written to the image's filesystem is lost).  To handle persistent
state that needs to persist after the Docker equivalent of a reboot or
upgrades (like uploaded files or the Zulip database), container
systems let you configure certain directories inside the container
from the host system's filesystem.

For example, this project's `docker-compose.yml` configuration file
specifies a set of volumes where
[persistent Zulip data][persistent-data] should be stored under
`/opt/docker/zulip/` in the container host's file system:

* `/opt/docker/zulip/postgresql/data/` has the postgres container's
  persistent storage (i.e. the database).
* `/opt/docker/zulip/zulip/` has the application server container's
  persistent storage, including the secrets file, uploaded files,
  etc.

This approach of mounting `/opt/docker` into the container is the
right model if you're hosting your containers from a single host
server, which is how `docker-compose` is intended to be used.  If
you're using Kubernetes, Docker Swarm, or another cloud container
service, then these persistent storage volumes are typically
configured to be network block storage volumes (e.g. an Amazon EBS
volume) so that they can be mounted from any server within the
cluster.

What this means is that if you're using `docker-zulip` in production
with `docker-compose`, you'll want to configure your backup system to
do backups on the `/opt/zulip/docker` directory, in order to ensure
you don't lose data.

[persistent-data]: https://zulip.readthedocs.io/en/latest/production/maintain-secure-upgrade.html#backups

## Prerequisites

To use `docker-zulip`, you need the following:

* An installation of [Docker][install-docker] and
  [Docker Compose][install-docker-compose] or a Kubernetes runtime
  engine.
* At least ~1GB of available RAM.  For running the Zulip system
  (including databases, etc.) on a single VM not using Docker, we
  [recommend at least 2GB of available RAM][prod-requirements] for
  running a production Zulip server.  But if you're just testing
  and/or aren't expecting a lot of users/messages, you can get away
  with significantly less, because Docker makes it easy to sharply
  limit the RAM allocated to the services Zulip depends on, like
  redis, memcached, and postgresql (at the cost of potential
  performance issues).

[install-docker]: https://docs.docker.com/install/
[install-docker-compose]: https://docs.docker.com/compose/install/
[prod-overview]: https://zulip.readthedocs.io/en/latest/production/overview.html
[prod-requirements]: https://zulip.readthedocs.io/en/latest/production/requirements.html

## Running a Zulip server with docker-compose

To use this project, we recommend starting by cloning the repo (since
you'll want to edit the `docker-compose.yml` file in this project):

```
git clone https://github.com/galexrt/docker-zulip.git
cd docker-zulip
# Edit `docker-compose.yml` to configure; see docs below
```

If you're in hurry to try Zulip, you can skip to
[start the Zulip server](#starting-the-server), but for production
use, you'll need to do some configuration.

### Configuration

With `docker-compose`, it is traditional to configure a service by
setting environment variables declared in the `zulip -> environment`
section of the `docker-compose.yml` file; this image follows that
convention.

**Mandatory settings**.  You must configure these settings (more
discussion in the main [Zulip installation docs][install-normal]):

* `SETTINGS_EXTERNAL_HOST`: The hostname your users will use to
  connect to your Zulip server.  If you're testing on your laptop, you
  the default of `localhost.localdomain` is great.
* `SETTINGS_ZULIP_ADMINISTRATOR`: The email address to receive error
  and support emails generated by the Zulip server and its users.

**Mandatory settings for serious use**.  Before you allow
production traffic, you need to also set these:

* `POSTGRES_PASSWORD` and `SECRETS_postgres_password` should both be a
  password for the Zulip container to authenticate to the Postgres
  container.  Since you won't use this directly, you just want a long,
  randomly generated string.  You can rotate these by just restarting
  the container.
* `RABBITMQ_DEFAULT_PASS` and `SECRETS_rabbitmq_password` are similar,
  just for the RabbitMQ container.
* `SECRETS_secret_key` should be a long (e.g. 50 characters), random
  string.  This value is important to keep secret and constant over
  time, since it is used to (among other things) sign login cookies.
* `SETTINGS_EMAIL_*`: Where you configure Zulip's ability to send
  [outgoing email][outgoing-email].

**Other settings**. If an environment variable name doesn't start with
`SETTINGS` or `SECRETS` in `docker-compose.yml`, it is specific to the
Docker environment.  Standard [Zulip server settings][server-settings]
are secrets are set using the following syntax:

* `SETTINGS_MY_SETTING` will become `MY_SETTING` in
  `/etc/zulip/settings.py`
* `SECRETS_my_secret` will become `my_secret` in
  `/etc/zulip/zulip-secrets.conf`.

Reading the comments in the sample
[Zulip's settings.py file][prod-settings-template]) is the best way to
learn about the full set of Zulip's supported server-level settings.

Most settings in Zulip are just strings, but some are lists (etc.)
which you need to encode in the YAML file.  For example,

* For `AUTHENTICATION_BACKENDS`, you enter `ZULIP_AUTH_BACKENDS` as a
  comma-separated list of the backend names
  (E.g. `"EmailAuthBackend,GitHubAuthBackend"`).

**SSL Certificates**.  By default, the image will generate a
  self-signed cert.  We
  [will soon also support certbot](https://github.com/galexrt/docker-zulip/issues/120)
  for this, just like we do in normal Zulip installations
  (contributions welcome!).

You can also provide an SSL certificate for your Zulip server by
putting it in `/opt/docker/zulip/zulip/certs/` (by default, the
`zulip` container startup script will generate a self-signed certificate and
install it in that directory).

### Manual configuration

The way the environment variables configuration process described in
the last section works is that the `entrypoint.sh` script that runs
when the Docker image starts up will generate a
[Zulip settings.py file][server-settings] file based on your settings
every time you boot the container.  This is convenient, in that you
only need to edit the `docker-compose.yml` file to configure your
Zulip server's settings.

An alternative approach is to set `MANUAL_CONFIGURATION: "True"` and
`LINK_SETTINGS_TO_DATA` in `docker-compose.yml`.  If you do that, you
can provide a `settings.py` file and a `zulip-secrets.conf` file in
`/opt/docker/zulip/zulip/`, and the container will use those.

### Starting the server

You can boot your Zulip installation with:

```
docker-compose up
```

This will boot the 5 containers declared in `docker-compose.yml`.  The
`docker-compose` command will print a bunch of output, and then
eventually hang once everything is happily booted, usually ending with
a bunch of lines like this:

```
rabbitmq_1   | =INFO REPORT==== 27-May-2018::23:26:58 ===
rabbitmq_1   | accepting AMQP connection <0.534.0> (172.18.0.3:49504
-> 172.18.0.5:5672)
```

You can inspect what containers are running in another shell with
`docker-compose ps` (remember to `cd` into the `docker-zulip`
directory first).

If you hit `Ctrl-C`, that will stop your Zulip server cluster.  If
you'd prefer to have the containers run in the background, you can use
`docker-compose up -d`.

### Connecting to your Zulip server

You can now connect to your Zulip server.  For example, if you set
this up on a laptop with the default port mappings and
`SETTINGS_EXTERNAL_HOST`, typing `http://localhost/` will take you to
your server.  Note that in this default scenario, (1) you'll have to
proceed past a self-signed SSL error, and (2) you won't be able to
login until you create an organization, but visiting the URL is a good
way to confirm that your networking configuration is working
correctly.

You can now follow the normal instructions for how to
[create a Zulip organization and log in][create-organization] to your
new Zulip server (though see the following section for how to run
management commands).

### Running management commands

From time to time, you'll need to attach a shell to the Zulip
container so that you can run `manage.py` commands, check logs, etc.
The following are helpful examples:

```bash
# Get a (root) shell in the container so you can access logs
docker-compose exec zulip /bin/bash
# Create the initial Zulip organization
docker-compose exec zulip sudo -H -u zulip -g zulip /home/zulip/deployments/current/manage.py generate_realm_creation_link
```

Since that process for running management commands is a pain, we recommend
[using a wrapper script][wrapper-tool] for running management commands.

[wrapper-tool]: https://github.com/galexrt/docker-zulip/wiki/Running-Management-Commands

## Running a Zulip server with Kubernetes

A Kubernetes pod file is in the `kubernetes/` folder; you can run it
with `kubectl create -f ./kubernetes/`.

You should read the `docker-compsoe` section above to understand how
this works, since it's a very similar setup.  You'll want to to clone
this repository, and edit the `zulip-rc.yml` to configure the image, etc.

### Installing minikube for testing

The fastest way to get Kubernetes up and running for testing without
signing up for a cloud service is to install
[Minikube][install-minikube] on your system.

[install-minikube]: https://kubernetes.io/docs/tasks/tools/install-minikube/

### Helm charts

We are aware of two efforts at building Helm Charts for Zulip:
* [A PR to the main Helm repo](https://github.com/kubernetes/charts/pull/5168/files),
  which is further along.
* [The zulip-helm project](https://github.com/armooo/zulip-helm),
  which might be a helpful reference for work on this.

Contributions to finish either of those and get them integrated are
very welcome!  If you're interested in helping with this, post on
[this thread][helm-chart-thread].

[helm-chart-thread]: https://chat.zulip.org/#narrow/stream/21-provision-help/subject/K8.20and.20Helm/near/589098

### Scaling out and high availability

This image is not designed to make it easy to run multiple copies of
the `zulip` application server container (and you need to know a lot
about Zulip to do this sort of thing successfully).  If you're
interested in running a high-availablity Zulip installation, your best
bet is to get in touch with the Zulip support team at
`support@zulipchat.com`.

## Networking and reverse proxy configuration

When running your container in production, you may want to put your
Zulip container behind an HTTP proxy.
[This wiki page][proxy-wiki-page] documents how to do this correctly
with `nginx`.

[proxy-wiki-page]: https://github.com/galexrt/docker-zulip/wiki/Proxying-via-nginx-on-host-machine

## Upgrading the Zulip container

You can upgrade your Zulip installation to any newer version of Zulip
with the following instructions.  At a high level, the strategy is to
download a new image, stop the `zulip` container, and then boot it
back up with the new image.  When the upgraded `zulip` container boots
the first time, it will run the necessary database migrations with
`manage.py migrate`.

If you ever find you need to downgrade your Zulip server, you'll need
to use `manage.py migrate` to downgrade the database schema manually.

### Using `docker-compose`

0. (Optional) Upgrading does not delete your data, but it's generally
   good practice to
   [back up your Zulip data](http://zulip.readthedocs.io/en/latest/prod-maintain-secure-upgrade.html#backups)
   before upgrading to make switching back to the old version
   simple. You can find your docker data volumes by looking at the
   `volumes` lines in `docker-compose.yml`
   e.g. `/opt/docker/zulip/postgresql/data/`.

1. Pull the new image version, e.g. for `v1.8.1` run: `docker pull
quay.io/galexrt/zulip:v1.8.1`.

2. Edit your `docker-compose.yml` to point to the new image version,
e.g.:
```yml
zulip:
  image: "quay.io/galexrt/zulip:1.8.1-0"
```

3. You can execute the upgrade by running:

```
# Stops the old zulip container; this beings your downtime
docker-compose stop
# Boots the new zulip container; this ends your downtime
docker-compose up
# Deletes the old container images
docker-compose rm
```

That's it! Zulip is now running the updated version.
You can confirm you're running the latest version by running:

```bash
docker exec -it YOUR_ZULIP_CONTAINER_ID_HERE su -- zulip -c "cat
/home/zulip/deployments/current/version.py"
```

(Replace `YOUR_ZULIP_CONTAINER_ID_HERE` with your container id, which
you can find using `docker ps`)

### Upgrading from a Git repository

1. Edit `Dockerfile` in this directory to specify the Git repository
and the commit to use as `ZULIP_GIT_URL` and `ZULIP_GIT_REF`
(e.g. `master` or `1.8.1` or
`445932cc8613c77ced023125248c8b966b3b7528`).

2. Edit your `docker-compose.yml` to comment out the `image` line, e.g.:

```
  zulip:
    # image: "quay.io/galexrt/zulip:1.8.1-0"
    build:
      context: .
```

3. Run `docker-compose build zulip` to build a Zulip Docker image from
   the specified Git version.

Then stop and restart the container as described in the previous section.

## Troubleshooting

Common issues include:

* Invalid configuration resulting in the `zulip` container not
  starting; check `docker-compose ps` to see if it started, and then
  read the logs for the Zulip container to see why it failed.
* A new Zulip setting not being passed through the Docker
  [entrypoint.sh script](/entrypoint.sh) properly.  If you
  run into this sort of problem you can work around it by specifying a
  `ZULIP_CUSTOM_SETTINGS` with one setting per line below, but please
  report an issue so that we can fix this for everyone else.

## Community support

You can get community support and tell the developers about your
experiences using this project on
[#production-help](https://chat.zulip.org/#narrow/stream/31-production-help) on
[chat.zulip.org](https://chat.zulip.org/), the Zulip community server.

In late May 2018, we completed a complete rewrite of this project's
documentation, so we'd love any and all feedback!

## Contributing

We love community contributions, and respond quickly to issues and
PRs.  Some particularly useful ways to contribute right now are:

* Contribute to this documentation by opening issues about what
  confused you or submitting pull requests!
* Reporting bugs or rough edges!

## Credits

Huge thanks to everyone who has contributed.  Special thanks to
[Alexander Trost](http://github.com/galexrt/), who created
`docker-zulip` and did a huge amount of the early work required to
make a high-quality Docker image for Zulip possible.

[install-normal]: https://zulip.readthedocs.io/en/latest/production/install.html#installer-options
[outgoing-email]: https://zulip.readthedocs.io/en/latest/production/email.html
[server-settings]: https://zulip.readthedocs.io/en/latest/production/settings.html
[prod-settings-template]: https://github.com/zulip/zulip/blob/master/zproject/prod_settings_template.py
[create-organization]: http://zulip.readthedocs.io/en/latest/production/install.html#step-3-create-a-zulip-organization-and-log-in
