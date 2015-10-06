#!/bin/bash
set -x

MANAGE_PY="$ZULIP_DIR/deployments/current/manage.py"
ZULIP_CURRENT_DEPLOY="$ZULIP_DIR/deployments/current"

# TODO (See Issue #2): Is this really needed? Find out where images are saved.
# Create assets link to the DATA_DIR
if [ ! -d "$DATA_DIR/assets" ]; then
   mkdir -p "$DATA_DIR/assets"
   cp -rf "$ZULIP_DIR/assets/*" "$DATA_DIR/assets"
   touch "$DATA_DIR/assets/.linked"
fi
ln -sf "$DATA_DIR/assets" "$ZULIP_CURRENT_DEPLOY/assets"

function configure-rabbitmq(){
  rabbitmqctl delete_user zulip || :
  rabbitmqctl delete_user guest || :
  rabbitmqctl add_user zulip "$("$ZULIP_CURRENT_DEPLOY/bin/get-django-setting" RABBITMQ_PASSWORD)" || :
  rabbitmqctl set_user_tags zulip administrator
  rabbitmqctl set_permissions -p / zulip '.*' '.*' '.*'
}

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
configure-rabbitmq

if [ ! -f "$DATA_DIR/.initiated" ]; then
  echo "Initiating Zulip ..."
  # Generate the secrets
  /root/zulip/scripts/setup/generate_secrets.py

  # Without the secrets we can't update the prod-static files :(
  # Is update-prod-static really needed? #QuestionsOverQuestions
  "$ZULIP_DIR/deployments/current/tools/update-prod-static"
  ls -ahl "$ZULIP_DIR" "$ZULIP_DIR/deployments/current" "$ZULIP_DIR/deployments/current/prod-static"
  cp -rfT "$ZULIP_DEPLOY_PATH/prod-static/serve" "$ZULIP_DIR/prod-static"

  # Init Postgres database server
  postgres-init-db

  # Modify settings.py here
  cat /etc/settings.py

  # Init database with something (data? :D)
  if ! initialize-database; then
    echo "initialize-database failed"
    exit 1
  fi
  touch "$DATA_DIR/.initiated"
  echo "Initiated Zulip"
fi

# If update is set do
if [ ! -f "$ZULIP_DIR/.zulip-$ZULIP_VERSION" ]; then
  # as root do $MANAGE_PY(./manage.py) migrate
  "$MANAGE_PY" migrate
fi

# Exec supervisord
exec supervisord
