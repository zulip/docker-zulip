#!/bin/bash
set -x

MANAGE_PY="$ZULIP_DIR/deployments/current/manage.py"
ZULIP_CURRENT_DEPLOY="$ZULIP_DIR/deployments/current"

# TODO Is this really needed? Find out where images are saved.
# Create assets link to the DATA_DIR
#ln -sf "$DATA_DIR" "$ZULIP_CURRENT_DEPLOY/assets"

# Taken from /home/zulip/deployments/current/scripts/setup/postgres-init-db
# A little modification was needed to work with this setup
function postgres-init-db(){
  if [ -z "$PGPASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
  fi
  psql -h "$DB_HOST" -p "$DB_PORT" -u "$DB_USER" "CREATE USER zulip;
    ALTER ROLE zulip SET search_path TO zulip,public;
    DROP DATABASE IF EXISTS zulip;
    CREATE DATABASE zulip OWNER=zulip;" || :
  psql -h "$DB_HOST" -p "$DB_PORT" -u "$DB_USER" zulip "CREATE SCHEMA zulip AUTHORIZATION zulip;
    CREATE EXTENSION tsearch_extras SCHEMA zulip;" || :
  return 0
}

function initialize-database(){
  cd "$ZULIP_CURRENT_DEPLOY"
  su zulip -c "$MANAGE_PY checkconfig"
  su zulip -c "$MANAGE_PY migrate --noinput"
  su zulip -c "$MANAGE_PY createcachetable third_party_api_results"
  if ! su zulip -c "$MANAGE_PY initialize_voyager_db"; then
    return 1
  fi
  return 0
}

# Configure rabbitmq server everytime because it could be a new one ;)
"$ZULIP_CURRENT_DEPLOY/scripts/setup/configure-rabbitmq"

if [ ! -f "$ZULIP_DIR/.initiated" ]; then
  echo "Initiating Zulip ..."
  # Init Postgres database server
  postgres-init-db

  # Modify settings.py here
  cat /etc/settings.py

  # Init database with something (data? :D)
  if ! initialize-database; then
    echo "initialize-database failed"
    exit 1
  fi
  touch "$ZULIP_DIR/.initiated"
  echo "Initiated Zulip"
fi

# If update is set do
if [ ! -f "$ZULIP_DIR/.zulip-$ZULIP_VERSION" ]; then
  # as root do $MANAGE_PY(./manage.py) migrate
  "$MANAGE_PY" migrate
fi

# Exec supervisord
exec supervisord
