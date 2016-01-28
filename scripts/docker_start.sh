#!/bin/bash

CONTAINERS=(zulip_database zulip_memcached zulip_rabbitmq zulip_redis zulip_zulip)
for CONTAINER_NAME in $"${CONTAINERS[@]}";
do
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
done

docker run \
    -d \
    --name=zulip_database \
    -e "DB_NAME=user" \
    -e "DB_USER=zulip" \
    -e "DB_PASS=zulip" \
    -v /opt/docker/zulip/postgresql:/var/lib/postgresql:rw \
    quay.io/galexrt/zulip-postgresql-tsearchextras:latest
docker run \
    -d \
    --name=zulip_memcached \
    --restart=always \
    quay.io/sameersbn/memcached:latest
docker run \
    -d \
    --name=zulip_rabbitmq \
    --hostname=zulip-rabbitmq \
    -e "RABBITMQ_DEFAULT_USER=zulip" \
    -e "RABBITMQ_DEFAULT_PASS=zulip" \
    docker.io/rabbitmq:3.5.5
docker run \
    -d \
    --name=zulip_redis \
    -v /opt/docker/zulip/redis:/var/lib/redis:rw \
    quay.io/galexrt/camo:latest
docker run \
    -d \
    --name=zulip_zulip \
    -v /opt/docker/zulip/zulip:/data:rw \
    --link=zulip_database:database \
    --link=zulip_memcached:memcached \
    --link=zulip_rabbitmq:rabbitmq \
    --link=zulip_redis:redis \
    -p 80:80 \
    -p 443:443 \
    -v /opt/docker/zulip/zulip:/data:rw \
    -e "DB_HOST=database" \
    -e "MEMCACHED_HOST=memcached" \
    -e "REDIS_HOST=redis" \
    -e "RABBITMQ_HOST=rabbitmq" \
    -e "ZULIP_USER_EMAIL=example@example.com" \
    -e "ZULIP_USER_DOMAIN=example.com" \
    -e "ZULIP_AUTH_BACKENDS=EmailAuthBackend" \
    -e "ZULIP_SECRETS_email_password=12345" \
    -e "ZULIP_SECRETS_rabbitmq_password=zulip" \
    -e "ZULIP_SETTINGS_EXTERNAL_HOST=example.com" \
    -e "ZULIP_SETTINGS_ZULIP_ADMINISTRATOR=admin@example.com" \
    -e "ZULIP_SETTINGS_ADMIN_DOMAIN=example.com" \
    -e "ZULIP_SETTINGS_NOREPLY_EMAIL_ADDRESS=noreply@example.com" \
    -e "ZULIP_SETTINGS_DEFAULT_FROM_EMAIL=Zulip <noreply@example.com>" \
    -e "ZULIP_SETTINGS_EMAIL_HOST=smtp.example.com" \
    -e "ZULIP_SETTINGS_EMAIL_HOST_USER=noreply@example.com" \
    quay.io/galexrt/zulip:v1.3.10
