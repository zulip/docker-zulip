#!/bin/sh

docker compose exec -u zulip zulip /home/zulip/deployments/current/manage.py "$@"
