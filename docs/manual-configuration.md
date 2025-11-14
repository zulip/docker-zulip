# Manual configuration

The way the environment variables configuration process described in
the last section works is that the `entrypoint.sh` script that runs
when the Docker image starts up will generate a
[Zulip settings.py file][server-settings] file based on your settings
every time you boot the container. This is convenient, in that you
only need to edit the `docker-compose.yml` file to configure your
Zulip server's settings.

An alternative approach is to set `MANUAL_CONFIGURATION: "True"` and
`LINK_SETTINGS_TO_DATA: "True"` in `docker-compose.yml`. If you do that, you
can provide a `settings.py` file and a `zulip-secrets.conf` file in
`/opt/docker/zulip/zulip/settings/etc-zulip/`, and the container will use those.

[server-settings]: https://zulip.readthedocs.io/en/latest/production/settings.html
