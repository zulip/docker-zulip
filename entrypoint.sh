#!/bin/bash
set -x
set -e

MANAGE_PY="$ZULIP_DIR/deployments/current/manage.py"
ZULIP_CURRENT_DEPLOY="$ZULIP_DIR/deployments/current"

function configure-rabbitmq(){
  rabbitmqctl delete_user zulip || :
  rabbitmqctl delete_user guest || :
  rabbitmqctl add_user zulip "$("$ZULIP_CURRENT_DEPLOY/bin/get-django-setting" RABBITMQ_PASSWORD)" || :
  rabbitmqctl set_user_tags zulip administrator
  rabbitmqctl set_permissions -p / zulip '.*' '.*' '.*'
}

function add-custom-zulip-secrets(){
  ZULIP_SECRETS="/etc/zulip/zulip-secrets.conf"
  for SECRET_KEY in ("google_oauth2_client_secret" "email_password" "twitter_consumer_key" "s3_key" "s3_secret_key" "twitter_consumer_secret" "twitter_access_token_key" "twitter_access_token_secret"); do
    SECRET_VAR="${!ZULIP_SECRETS_$SECRET_KEY}"
    if [ -z "$SECRET_VAR" ]; then
      set +x
      echo "No settings env var found for key \"$SECRET_KEY\". Continuing."
      set -x
      continue
    fi
    set +x
    echo "Setting secret \"$SECRET_KEY\"."
    echo "$SECRET_KEY = '$SECRET_VAR'" >> "$ZULIP_SECRETS"
    set -x
  done
}

# Taken from the zulip/zulip but modified it a bit
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

function setup-zulip-settings(){
  ZULIP_SETTINGS="/etc/zulip/settings.py"
  if [ "$ZULIP_USE_EXTERNAL_SETTINGS" == "true" ] && [ -f "$DATA_DIR/settings.py" ]; then
    rm -f "$ZULIP_SETTINGS"
    cp -rf "$DATA_DIR/settings.py" "$ZULIP_SETTINGS"
    chown zulip:zulip "$ZULIP_SETTINGS"
    return 0
  fi
  # ^#?([a-zA-Z0-9_]*)[ ]*=[ ]*([\"'].*[\"']+|[\(\{]+(\n[^)]*)+.*[\)\}])$ and ^#?[ ]?([a-zA-Z0-9_]*)
  for SETTING_KEY in $(grep -E "^#?([a-zA-Z0-9_]*)[ ]*=[ ]*([\"'].*[\"']+|[\(\{]+(\n[^)]*)+.*[\)\}])$" "$ZULIP_SETTINGS" | grep -oE "^#?[ ]?([a-zA-Z0-9_]*)") "S3_AUTH_UPLOADS_BUCKET" "S3_AVATAR_BUCKET"; do
    SETTING_VAR="${!ZULIP_SETTINGS_$SETTING_KEY}"
    if [ -z "$SETTING_VAR" ]; then
      set +x
      echo "No settings env var found for key \"$SETTING_KEY\". Continuing."
      set -x
      continue
    fi
    set +x
    echo "Setting key \"$SETTING_KEY\" to value \"$SETTING_VAR\"."
    set -x
    sed -i "s~#?${SETTING_KEY}[ ]*=[ ]*['\"]+.*['\"]+$~${SETTING_KEY} = '${SETTING_VAR}'~g" "$ZULIP_SETTINGS"
  done
  if [ -z "$ZULIP_SAVE_SETTINGS_PY" ]; then
    rm -f "$DATA_DIR/settings.py"
    cp -f "$ZULIP_SETTINGS" "$DATA_DIR/settings.py"
  fi
}

function zulip-create-user(){
  if [ -z "$ZULIP_USER_EMAIL" ]; then
    set +x
    echo "No zulip user email given."
    set -x
    return 1
  fi
    if [ -z "$ZULIP_USER_PASSWORD" ]; then
      set +x
      echo "No zulip user password given."
      set -x
      return 1
    fi
  if [ -z "$ZULIP_USER_FULLNAME" ]; then
    set +x
    echo "No zulip user full name given. Defaulting to \"Zulip Docker\""
    set -x
    ZULIP_USER_FULLNAME="Zulip Docker"
  fi
  su zulip -c " $MANAGE_PY create_user --new-email \"$ZULIP_USER_EMAIL\" --new-password \"$ZULIP_USER_PASSWORD\" --new-full-name \"$ZULIP_USER_FULLNAME\""
  su zulip -c "$MANAGE_PY knight \"$ZULIP_USER_EMAIL\" -f"
}

# TODO (See Issue #2): Is this really needed? Find out where images are saved.
# Create assets link to the DATA_DIR
if [ ! -d "$DATA_DIR/assets" ]; then
   mkdir -p "$DATA_DIR/assets"
   mv -rf "$ZULIP_CURRENT_DEPLOY/assets" "$DATA_DIR/assets"
fi
ln -sfT "$DATA_DIR/assets" "$ZULIP_CURRENT_DEPLOY/assets"

# Configure rabbitmq server everytime because it could be a new one ;)
configure-rabbitmq

if [ ! -f "$DATA_DIR/.initiated" ]; then
  set +x
  echo "Initiating Zulip Installation ..."
  echo "==="
  echo "Generating and setting secrets ..."
  set -x
  # Generate the secrets
  /root/zulip/scripts/setup/generate_secrets.py
  add-custom-zulip-secrets
  set +x
  echo "Secrets generated and set."
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
  set +x
  echo "Database setup done."
  echo "Setting Zulip settings ..."
  set -x
  # Setup zulip settings
  setup-zulip-settings
  set +x
  echo "Zulip settings setup done."
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
  echo "Creating zulip user account ..."
  set -x
  zulip-create-user
  set +x
  echo "Created zulip user account"
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
