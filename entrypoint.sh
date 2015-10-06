#!/bin/bash
set -x
set -e

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
  # Don't "leak" the password out
  set +x
  if [ -z "$PGPASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
  fi
  set -x
  psql -h "$DB_HOST" -p "$DB_PORT" -u "$DB_USER" "CREATE USER zulip;
    ALTER ROLE zulip SET search_path TO zulip,public;
    DROP DATABASE IF EXISTS zulip;
    CREATE DATABASE zulip OWNER=zulip;"
  psql -h "$DB_HOST" -p "$DB_PORT" -u "$DB_USER" zulip "CREATE SCHEMA zulip AUTHORIZATION zulip;
    CREATE EXTENSION tsearch_extras SCHEMA zulip;" || :
}

function initialize-database(){
  cd "$ZULIP_CURRENT_DEPLOY"
  su zulip -c "$MANAGE_PY checkconfig"
  su zulip -c "$MANAGE_PY migrate --noinput"
  su zulip -c "$MANAGE_PY createcachetable third_party_api_results"
  su zulip -c "$MANAGE_PY initialize_voyager_db"
}

# Configure rabbitmq server everytime because it could be a new one ;)
configure-rabbitmq

if [ ! -f "$DATA_DIR/.initiated" ]; then
  set +x
  echo "Initiating Zulip Installation ..."
  echo "==="
  echo "Generating secrets ..."
  set -x
  # Generate the secrets
  /root/zulip/scripts/setup/generate_secrets.py
  set +x
  echo "Secrets generated."
  echo "Creating/updating statics ..."
  set -x
  # Without the secrets we can't update the prod-static files :(
  # Is update-prod-static really needed? #QuestionsOverQuestions
  "$ZULIP_DIR/deployments/current/tools/update-prod-static"
  ls -ahl "$ZULIP_DIR" "$ZULIP_DIR/deployments/current" "$ZULIP_DIR/deployments/current/prod-static"
  cp -rfT "$ZULIP_DEPLOY_PATH/prod-static/serve" "$ZULIP_DIR/prod-static"
  set +x
  echo "Statics created/updated."
  echo "Setup database server ..."
  set -x
  # Init Postgres database server
  postgres-init-db

  # Modify settings.py here
  cat /etc/settings.py

  set +x
  echo "Database setup done."
  echo "Initiating  Database ..."
  set -x
  # Init database with something (data? :D)
  if ! initialize-database; then
    set +x
    echo "Database initiation failed."
    set -x
    exit 1
  fi
  touch "$DATA_DIR/.initiated"
  set +x
  echo "Database initiated."
  echo "==="
  echo "Zulip initiation done."
  set -x
fi

# If update is set do
if [ ! -f "$ZULIP_DIR/.zulip-$ZULIP_VERSION" ]; then
  set +x
  echo "Starting zulip migration ..."
  set -x
  # as root do $MANAGE_PY(./manage.py) migrate
  if ! "$MANAGE_PY" migrate; then
    set +x
    echo "Zulip migration error."
    set -x
    exit 1
  fi
  set +x
  echo "Zulip migration done."
  set -x
fi

set +x
echo "Starting zulip ..."
set -x
# Start supervisord
exec supervisord
