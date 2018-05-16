The custom_zulip_files mechanism allows you to test edits to Zulip
before making changes in the upstream repo.  It works by copying the
contents of this directory on top of the main zulip/zulip checkout as
part of the Docker build process.

As an example, if you want to test a change to
`scripts/setup/generate-self-signed-cert`, you would grab a copy of
the script from zulip/zulip, place it at
`custom_zulip_files/scripts/setup/generate-self-signed-cert`, make
your local edits, and then run `docker-compose build`.
