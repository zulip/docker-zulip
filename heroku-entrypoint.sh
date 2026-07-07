#!/bin/bash
set -e

parse_url() {
    local url="$1"

    local after_scheme="${url#*://}"
    local userinfo="${after_scheme%%@*}"

    PARSED_USERNAME="${userinfo%%:*}"
    PARSED_PASSWORD="${userinfo#*:}"

    local after_at="${url#*@}"
    local host_and_port="${after_at%%/*}"

    PARSED_HOST="${host_and_port%%:*}"
    PARSED_PORT="${host_and_port##*:}"
    PARSED_PATH="${after_at#*/}"
}

# Postgres
if [ -n "${DATABASE_URL:-}" ]; then
    parse_url "$DATABASE_URL"
    export SETTING_REMOTE_POSTGRES_HOST="$PARSED_HOST"
    export SETTING_REMOTE_POSTGRES_PORT="$PARSED_PORT"
    export SECRETS_POSTGRES_PASSWORD="$PARSED_PASSWORD"
fi

# RabbitMQ
if [ -n "${CLOUDAMQP_URL:-}" ]; then
    parse_url "$CLOUDAMQP_URL"
    export SETTING_RABBITMQ_HOST="$PARSED_HOST"
    export SECRETS_RABBITMQ_PASSWORD="$PARSED_PASSWORD"
fi

# Redis
if [ -n "${REDIS_URL:-}" ]; then
    parse_url "$REDIS_URL"
    export SETTING_REDIS_HOST="$PARSED_HOST"
    export SECRETS_REDIS_PASSWORD="$PARSED_PASSWORD"
fi

# Memcached
if [ -n "${MEMCACHIER_SERVERS:-}" ]; then
    parse_url "$MEMCACHIER_SERVERS"
    export SETTING_MEMCACHED_LOCATION="${PARSED_HOST}:${PARSED_PORT}"
    export SECRETS_MEMCACHED_PASSWORD="$PARSED_PASSWORD"
fi

# Hand off to the real Zulip entrypoint, passing along whatever
# command was given to us (e.g. "app:run")
exec /sbin/zulip-entrypoint.sh "$@"
