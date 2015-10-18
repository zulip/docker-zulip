#!/bin/bash

if [ "$DEBUG" == "true" ]; then
    set -x
    set -o functrace
fi
set -e

ZULIP_CURRENT_DEPLOY="$ZULIP_DIR/deployments/current"
MANAGE_PY="$ZULIP_CURRENT_DEPLOY/manage.py"
ZULIP_SETTINGS="/etc/zulip/settings.py"
ZULIP_ZPROJECT_SETTINGS="$ZULIP_CURRENT_DEPLOY/zproject/settings.py"

# Some functions were originally taken from the zulip/zulip repo folder scripts
# But modified to fit the docker image :)
rabbitmqSetup(){
    rabbitmqctl delete_user guest || :
    rabbitmqctl add_user zulip "$RABBITMQ_PASSWORD" || :
    rabbitmqctl set_user_tags zulip administrator || :
    rabbitmqctl set_permissions -p / zulip '.*' '.*' '.*' || :
}
databaseSetup(){
    if [ -z "$DB_HOST" ]; then
        echo "No DB_HOST given."
        exit 2
    fi
    if [ -z "$DB_NAME" ]; then
        echo "No DB_NAME given."
        exit 2
    fi
    if [ -z "$DB_USER" ]; then
        echo "No DB_USER given."
        exit 2
    fi
    if [ -z "$DB_PASSWORD" ]; then
        echo "No DB_PASSWORD given."
        exit 2
    fi
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
from zerver.lib.db import TimeTrackingConnection

REMOTE_POSTGRES_HOST = '$DB_HOST'

DATABASES = {
  "default": {
    'ENGINE': 'django.db.backends.postgresql_psycopg2',
    'NAME': '$DB_NAME',
    'USER': '$DB_USER',
    'PASSWORD': '$DB_PASSWORD',
    'HOST': '$DB_HOST',
    'SCHEMA': 'zulip',
    'CONN_MAX_AGE': 600,
    'OPTIONS': {
        'connection_factory': TimeTrackingConnection,
        'sslmode': 'prefer',
    },
  },
}
EOF
    if [ -z "$PGPASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    if [ -z "$DB_PORT" ]; then
        export DB_PORT="5432"
    fi
    local timeout=60
    echo -n "Waiting for database server to allow connections"
    while ! /usr/bin/pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -t 1 >/dev/null 2>&1
    do
        timeout=$(expr $timeout - 1)
        if [[ $timeout -eq 0 ]]; then
            echo "Could not connect to database server. Aborting..."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    sed -i "s~psycopg2.connect(\"user=zulip\")~psycopg2.connect(\"host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD\")~g" "/usr/local/bin/process_fts_updates"
    echo """
    CREATE USER zulip;
    ALTER ROLE zulip SET search_path TO zulip,public;
    DROP DATABASE IF EXISTS zulip;
    CREATE DATABASE zulip OWNER=zulip;
    """ | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" || :
    echo """
    CREATE SCHEMA zulip AUTHORIZATION zulip;
    CREATE EXTENSION tsearch_extras SCHEMA zulip;
    """ | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "zulip" || :
}
databaseInitiation(){
    su zulip -c "$MANAGE_PY checkconfig"
    echo "Migrating database ..."
    su zulip -c "$MANAGE_PY migrate --noinput"
    echo "Creating cache and third_party_api_results table ..."
    su zulip -c "$MANAGE_PY createcachetable third_party_api_results" || :
    echo "Initializing Voyager database ..."
    su zulip -c "$MANAGE_PY initialize_voyager_db" || :
}
secretsSetup(){
    local ZULIP_SECRETS="/etc/zulip/zulip-secrets.conf"
    local POSSIBLE_SECRETS=(
        "s3_key" "s3_secret_key" "android_gcm_api_key" "google_oauth2_client_secret"
        "dropbox_app_key" "mailchimp_api_key" "mandrill_api_key" "twitter_consumer_key" "twitter_consumer_secret"
        "twitter_access_token_key" "twitter_access_token_secret" "email_password" "rabbitmq_password"
    )
    for SECRET_KEY in "${POSSIBLE_SECRETS[@]}"; do
        local KEY="ZULIP_SECRETS_$SECRET_KEY"
        local SECRET_VAR="${!KEY}"
        if [ -z "$SECRET_VAR" ]; then
            echo "No settings env var for key \"$SECRET_KEY\"."
            continue
        fi
        echo "Setting secret \"$SECRET_KEY\"."
        if [ -z "$(grep "$SECRET_KEY" "$ZULIP_SECRETS")" ]; then
            sed -i -r "s~#?${SECRET_KEY}[ ]*=[ ]*['\"]+.*['\"]+$~${SECRET_KEY} = '${SECRET_VAR}'~g" "$ZULIP_SECRETS"
            continue
        fi
        echo "$SECRET_KEY = '$SECRET_VAR'" >> "$ZULIP_SECRETS"
    done
    unset SECRET_KEY
}
zulipSetup(){
    if [ ! -d "$DATA_DIR/certs" ]; then
        mkdir -p "$DATA_DIR/certs"
    fi
    if [ ! -e "/etc/ssl/private/zulip.key" ]; then
        if [ ! -e "$DATA_DIR/certs/zulip.key" ]; then
            echo "No zulip.key given in $DATA_DIR."
            return 1
        fi
        ln -sfT "$DATA_DIR/certs/zulip.key" "/etc/ssl/private/zulip.key"
    fi
    if [ ! -e "/etc/ssl/certs/zulip.combined-chain.crt" ]; then
        if [ ! -e "$DATA_DIR/certs/zulip.combined-chain.crt" ]; then
            echo "No zulip.combined-chain.crt given in $DATA_DIR."
            return 1
        fi
        ln -sfT "$DATA_DIR/certs/zulip.combined-chain.crt" "/etc/ssl/certs/zulip.combined-chain.crt"
    fi
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
CACHES = {
    'default': {
        'BACKEND':  'django.core.cache.backends.memcached.PyLibMCCache',
        'LOCATION': '$MEMCACHED_HOST:$MEMCACHED_PORT',
        'TIMEOUT':  $MEMCACHED_TIMEOUT
    },
    'database': {
        'BACKEND':  'django.core.cache.backends.db.DatabaseCache',
        'LOCATION':  'third_party_api_results',
        # Basically never timeout.  Setting to 0 isn't guaranteed
        # to work, see https://code.djangoproject.com/ticket/9595
        'TIMEOUT': 2000000000,
        'OPTIONS': {
            'MAX_ENTRIES': 100000000,
            'CULL_FREQUENCY': 10,
        }
    },
}
EOF
    # Authentication Backends
    local POSSIBLE_AUTH_BACKENDS=(
        "EmailAuthBackend" "ZulipRemoteUserBackend" "GoogleMobileOauth2Backend" "ZulipLDAPAuthBackend"
    )
    for AUTH_BACKEND_KEY in "${POSSIBLE_AUTH_BACKENDS[@]}"; do
        local KEY="ZULIP_AUTHENTICATION_BACKENDS_$AUTH_BACKEND_KEY"
        local AUTH_BACKEND_VAR="${!KEY}"
        if [ -z "$AUTH_BACKEND_VAR" ]; then
            echo "No authentication backend for key \"$AUTH_BACKEND_KEY\"."
            continue
        fi
        echo "Adding authentication backend \"$AUTH_BACKEND_KEY\"."
        AUTH_BACKENDS="$AUTH_BACKENDS'zproject.backends.$AUTH_BACKEND_VAR',"
    done
    sed -i "s~AUTHENTICATION_BACKENDS = (~AUTHENTICATION_BACKENDS = (\n$AUTH_BACKENDS~g" "$ZULIP_SETTINGS"
    # Rabbitmq settings
    sed -i "s~pika.ConnectionParameters('localhost',~pika.ConnectionParameters(settings.RABBITMQ_HOST,~g" "$ZULIP_CURRENT_DEPLOY/zerver/lib/queue.py"
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_HOST = '$RABBITMQ_HOST'
EOF
    if [ ! -z "$RABBITMQ_USERNAME" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_USERNAME = '$RABBITMQ_USERNAME'
EOF
    fi
    if [ ! -z "$RABBITMQ_PASSWORD" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_PASSWORD = '$RABBITMQ_PASSWORD'
EOF
    fi
    # Redis settings
    if [ -z "$REDIS_HOST" ]; then
        export REDIS_HOST="localhost"
    fi
    if [ -z "$REDIS_PORT" ]; then
        export REDIS_PORT="6379"
    fi
    case "$REDIS_RATE_LIMITING" in
        [Tt][Rr][Uu][Ee])
        export REDIS_RATE_LIMITING="True"
        ;;
        [Ff][Aa][Ll][Ss][Ee])
        export REDIS_RATE_LIMITING="False"
        ;;
        *)
        echo "Can't parse True or Right for REDIS_RATE_LIMITING. Defaulting to True"
        export REDIS_RATE_LIMITING="True"
        ;;
    esac
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RATE_LIMITING = $REDIS_RATE_LIMITING
REDIS_HOST = '$REDIS_HOST'
REDIS_PORT = $REDIS_PORT
EOF
    # Camo settings
    if [ ! -z "$CAMO_KEY" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
CAMO_KEY = '$CAMO_KEY'
EOF
    fi
    if [ ! -z "$CAMO_URI" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
CAMO_URI = '$CAMO_URI'
EOF
    fi
    if [ ! -z "$ZULIP_CUSTOM_SETTINGS" ]; then
        echo -e "\n$ZULIP_CUSTOM_SETTINGS" >> "$ZULIP_ZPROJECT_SETTINGS"
    fi
    local SET_SETTINGS=($(env | sed -nr "s/ZULIP_SETTINGS_([A-Z_]*).*/\1/p"))
    for SETTING_KEY in "${SET_SETTINGS[@]}"; do
        local KEY="ZULIP_SETTINGS_$SETTING_KEY"
        local SETTING_VAR="${!KEY}"
        if [ -z "$SETTING_VAR" ]; then
            echo "No settings env var for key \"$SETTING_KEY\"."
            continue
        fi
        echo "Setting key \"$SETTING_KEY\" to value \"$SETTING_VAR\"."
        sed -ri "s~#?${SETTING_KEY}[ ]*=[ ]*['\"]+.*['\"]+$~${SETTING_KEY} = '${SETTING_VAR}'~g" "$ZULIP_SETTINGS"
    done
    if [ "$ZULIP_COPY_SETTINGS" == "true" ]; then
        rm -f "$DATA_DIR/settings.py"
        cp -fT "$ZULIP_SETTINGS" "$DATA_DIR/settings.py"
    fi
    unset SETTING_KEY
}
zulipCreateUser(){
    if [ -z "$ZULIP_USER_EMAIL" ]; then
        echo "No zulip user email given."
        return 1
    fi
    if [ -z "$ZULIP_USER_DOMAIN" ]; then
        echo "No zulip user domain given."
        return 1
    fi
    if [ -z "$ZULIP_USER_PASSWORD" ]; then
        echo "No zulip user password given."
        return 1
    fi
    if [ -z "$ZULIP_USER_FULLNAME" ]; then
        echo "No zulip user full name given. Defaulting to \"Zulip Docker\""
        export ZULIP_USER_FULLNAME="Zulip Docker"
    fi
    su zulip -c "$MANAGE_PY create_user --this-user-has-accepted-the-tos \"$ZULIP_USER_EMAIL\" \"$ZULIP_USER_FULLNAME\" --domain \"$ZULIP_USER_DOMAIN\""
    su zulip -c "$MANAGE_PY knight \"$ZULIP_USER_EMAIL\" -f"
    cat | expect <<EOF
#!/usr/bin/expect
spawn su zulip -c "$MANAGE_PY changepassword $ZULIP_USER_EMAIL"
expect "Password:"
send_user "$ZULIP_USER_PASSWORD\n"
expect "Password (again):"
send_user "$ZULIP_USER_PASSWORD\n"
EOF
    return 0
}

if [ ! -d "$ZULIP_DIR/uploads" ]; then
    mkdir -p "$ZULIP_DIR/uploads"
fi
if [ -d "$DATA_DIR/uploads" ]; then
    rm -rf "$ZULIP_DIR/uploads"
else
    mkdir -p "$DATA_DIR/uploads"
    mv -f "$ZULIP_DIR/uploads" "$DATA_DIR/uploads"
fi
ln -sfT "$DATA_DIR/uploads" "$ZULIP_DIR/uploads"
# Configure rabbitmq server everytime because it could be a new one ;)
rabbitmqSetup
if [ ! -e "$DATA_DIR/.initiated" ]; then
    echo "Initiating Zulip initiation ..."
    echo "==="
    echo "Generating and setting secrets ..."
    # Generate the secrets
    /root/zulip/scripts/setup/generate_secrets.py
    secretsSetup
    echo "Secrets generated and set."
    echo "Setting Zulip settings ..."
    # Setup zulip settings
    if ! zulipSetup; then
        echo "Zulip setup failed."
        exit 1
    fi
    echo "Zulip settings setup done."
    echo "Setting up database settings and server ..."
    # setup database
    databaseSetup
    echo "Database setup done."
    echo "Initiating  Database ..."
    # Init database with something called data :D
    if ! databaseInitiation; then
        echo "Database initiation failed."
        exit 1
    fi
    echo "Database initiated."
    echo "Creating zulip user account ..."
    zulipCreateUser
    echo "Created zulip user account"
    echo "==="
    echo "Zulip initiation done."
    touch "$DATA_DIR/. "
fi
# If there's an "update" available, then JUST DO IT!
if [ ! -e "$DATA_DIR/.zulip-$ZULIP_VERSION" ]; then
    echo "Starting zulip migration ..."
    if ! "$MANAGE_PY" migrate; then
        echo "Zulip migration error."
        exit 1
    fi
    touch "$DATA_DIR/.zulip-$ZULIP_VERSION"
    echo "Zulip migration done."
fi
echo "Starting zulip using supervisor ..."
# Start supervisord
exec supervisord
