#!/bin/bash

if [ "$DEBUG" == "true" ]; then
    set -x
    set -o functrace
fi
set -e

# Custom env variables
# DB
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_HOST_PORT="${DB_HOST_PORT:-5432}"
DB_USER="${DB_USER:-zulip}"
DB_PASSWORD="${DB_PASSWORD:-zulip}"
DB_PASS="${DB_PASS:-$(echo $DB_PASSWORD)}"
DB_NAME="${DB_NAME:-zulip}"
# RabbitMQ
RABBITMQ_HOST="${RABBITMQ_HOST:-127.0.0.1}"
RABBITMQ_USERNAME="${RABBITMQ_USERNAME:-zulip}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-zulip}"
RABBITMQ_PASS="${RABBITMQ_PASS:-$(echo $RABBITMQ_PASSWORD)}"
RABBITMQ_SETUP="${RABBITMQ_SETUP:-True}"
# Redis
REDIS_RATE_LIMITING="${REDIS_RATE_LIMITING:-True}"
REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_HOST_PORT="${REDIS_HOST_PORT:-6379}"
# Memcached
MEMCACHED_HOST="${MEMCACHED_HOST:-127.0.0.1}"
MEMCACHED_HOST_PORT="${MEMCACHED_HOST_PORT:-11211}"
MEMCACHED_TIMEOUT="${MEMCACHED_TIMEOUT:-3600}"
# Zulip user setup
export ZULIP_USER_FULLNAME="${ZULIP_USER_FULLNAME:-Zulip Docker}"
export ZULIP_USER_DOMAIN="${ZULIP_USER_DOMAIN:-$(echo $ZULIP_SETTINGS_EXTERNAL_HOST)}"
export ZULIP_USER_EMAIL="${ZULIP_USER_EMAIL:-}"
export ZULIP_USER_PASSWORD="${ZULIP_USER_PASSWORD:-zulip}"
export ZULIP_USER_PASS="${ZULIP_USER_PASS:-$(echo $ZULIP_USER_PASSWORD)}"
# Zulip certifcate parameters
ZULIP_CERTIFICATE_SUBJ="${ZULIP_CERTIFICATE_SUBJ:-}"
ZULIP_CERTIFICATE_C="${ZULIP_CERTIFICATE_C:-US}"
ZULIP_CERTIFICATE_ST="${ZULIP_CERTIFICATE_ST:-Denial}"
ZULIP_CERTIFICATE_L="${ZULIP_CERTIFICATE_L:-Springfield}"
ZULIP_CERTIFICATE_O="${ZULIP_CERTIFICATE_O:-Dis}"
ZULIP_CERTIFICATE_CN="${ZULIP_CERTIFICATE_CN:-}"

# entrypoint.sh specific variables
ZULIP_CURRENT_DEPLOY="/home/zulip/deployments/current"
ZULIP_SETTINGS="/etc/zulip/settings.py"
ZULIP_ZPROJECT_SETTINGS="$ZULIP_CURRENT_DEPLOY/zproject/settings.py"

# Some functions were originally taken from the zulip/zulip repo folder scripts
# But modified to fit the docker image :)
rabbitmqSetup(){
    echo "RabbitMQ deleting user guest"
    rabbitmqctl -n "$RABBITMQ_HOST" delete_user guest 2> /dev/null || :
    if [ "$RABBITMQ_SETUP" != "False" ]; then
        echo "RabbitMQ adding user $RABBITMQ_USERNAME"
        rabbitmqctl -n "$RABBITMQ_HOST" add_user "$RABBITMQ_USERNAME" "$RABBITMQ_PASS" 2> /dev/null || :
        echo "RabbitMQ setting user tags \"$RABBITMQ_USERNAME\""
        rabbitmqctl -n "$RABBITMQ_HOST" set_user_tags "$RABBITMQ_USERNAME" administrator 2> /dev/null || :
        echo "RabbitMQ setting permissions for user \"$RABBITMQ_USERNAME\""
        rabbitmqctl -n "$RABBITMQ_HOST" set_permissions -p / "$RABBITMQ_USERNAME" '.*' '.*' '.*' 2> /dev/null || :
        echo "RabbitMQ set permissions for user"
    fi
    sed -ri "s~#?RABBITMQ_PASSWORD[ ]*=[ ]*['\"]+.*['\"]+$~RABBITMQ_PASSWORD = '$RABBITMQ_PASS'~g" "$ZULIP_SETTINGS"
    export ZULIP_SECRETS_rabbitmq_password="$RABBITMQ_PASS"
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
    if [ -z "$DB_PASS" ]; then
        echo "No DB_PASS given."
        exit 2
    fi
    if [ -z "$DB_HOST_PORT" ]; then
        export DB_HOST_PORT="5432"
    fi
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
from zerver.lib.db import TimeTrackingConnection

REMOTE_POSTGRES_HOST = '$DB_HOST'

DATABASES = {
  "default": {
    'ENGINE': 'django.db.backends.postgresql_psycopg2',
    'NAME': '$DB_NAME',
    'USER': '$DB_USER',
    'PASSWORD': '$DB_PASS',
    'HOST': '$DB_HOST',
    'PORT': '$DB_HOST_PORT',
    'SCHEMA': 'zulip',
    'CONN_MAX_AGE': 600,
    'OPTIONS': {
        'connection_factory': TimeTrackingConnection,
        'sslmode': 'prefer',
    },
  },
}
EOF
    export PGPASSWORD="$DB_PASS"
    local TIMEOUT=60
    echo -n "Waiting for database server to allow connections"
    while ! /usr/bin/pg_isready -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" -t 1 >/dev/null 2>&1
    do
        TIMEOUT=$(expr $TIMEOUT - 1)
        if [[ $TIMEOUT -eq 0 ]]; then
            echo "Could not connect to database server. Aborting..."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    sed -i "s~psycopg2.connect\(.*\)~psycopg2.connect(\"host=$DB_HOST port=$DB_HOST_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASS\")~g" "/usr/local/bin/process_fts_updates"
    echo """
    CREATE USER zulip;
    ALTER ROLE zulip SET search_path TO zulip,public;
    CREATE DATABASE zulip OWNER=zulip;
    CREATE SCHEMA zulip AUTHORIZATION zulip;
    """ | psql -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" || :
    echo "CREATE EXTENSION tsearch_extras SCHEMA zulip;" | \
        psql -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" "zulip" || :
    unset PGPASSWORD
}
databaseInitiation(){
    echo "Migrating database ..."
    su zulip -c "/home/zulip/deployments/current/manage.py migrate --noinput"
    echo "Creating cache and third_party_api_results table ..."
    su zulip -c "/home/zulip/deployments/current/manage.py createcachetable third_party_api_results" || :
    echo "Initializing Voyager database ..."
    su zulip -c "/home/zulip/deployments/current/manage.py initialize_voyager_db" || :
}
secretsSetup(){
    local POSSIBLE_SECRETS=(
        "email_password" "rabbitmq_password" "s3_key" "s3_secret_key" "android_gcm_api_key"
        "google_oauth2_client_secret" "dropbox_app_key" "mailchimp_api_key" "mandrill_api_key"
        "twitter_consumer_key" "twitter_consumer_secret" "twitter_access_token_key" "twitter_access_token_secret"
    )
    for SECRET_KEY in "${POSSIBLE_SECRETS[@]}"; do
        local KEY="ZULIP_SECRETS_$SECRET_KEY"
        local SECRET_VAR="${!KEY}"
        if [ -z "$SECRET_VAR" ]; then
            echo "No secret found for key \"$SECRET_KEY\"."
            continue
        fi
        echo "Secret found for \"$SECRET_KEY\"."
        if [ ! -z "$(grep "$SECRET_KEY" /etc/zulip/zulip-secrets.conf)" ]; then
            sed -i -r "s~#?${SECRET_KEY}[ ]*=[ ]*['\"]+.*['\"]+$~${SECRET_KEY} = '${SECRET_VAR}'~g" /etc/zulip/zulip-secrets.conf
            continue
        fi
        echo "$SECRET_KEY = $SECRET_VAR" >> /etc/zulip/zulip-secrets.conf
    done
    unset SECRET_KEY
}
zulipSetup(){
    if [ ! -d "$DATA_DIR/certs" ]; then
        mkdir -p "$DATA_DIR/certs"
    fi
    case "$ZULIP_AUTO_GENERATE_CERTS" in
        [Tt][Rr][Uu][Ee])
        export ZULIP_AUTO_GENERATE_CERTS="True"
        ;;
        [Ff][Aa][Ll][Ss][Ee])
        export ZULIP_AUTO_GENERATE_CERTS="False"
        ;;
        *)
        echo "Can't parse True or Right for ZULIP_AUTO_GENERATE_CERTS. Defaulting to True"
        export ZULIP_AUTO_GENERATE_CERTS="True"
        ;;
    esac
    if [ ! -z "$ZULIP_AUTO_GENERATE_CERTS" ] && [ "$ZULIP_AUTO_GENERATE_CERTS" == "True" ]; then
        if [ ! -e "$DATA_DIR/certs/zulip.key" ] && [ ! -e "/etc/ssl/certs/zulip.combined-chain.crt" ]; then
            echo "Certificates generation is true. Generating certificates ..."
            if [ -z "$ZULIP_CERTIFICATE_SUBJ" ]; then
                if [ -z "$ZULIP_CERTIFICATE_CN" ]; then
                    if [ -z "$ZULIP_SETTINGS_EXTERNAL_HOST" ]; then
                        echo "Certificates generation failed. Missing ZULIP_CERTIFICATE_CN and as backup ZULIP_SETTINGS_EXTERNAL_HOST not given."
                        exit 1
                    fi
                    export ZULIP_CERTIFICATE_CN="$ZULIP_SETTINGS_EXTERNAL_HOST"
                fi
                export ZULIP_CERTIFICATE_SUBJ="/C=$ZULIP_CERTIFICATE_C/ST=$ZULIP_CERTIFICATE_ST/L=$ZULIP_CERTIFICATE_L/O=$ZULIP_CERTIFICATE_O/CN=$ZULIP_CERTIFICATE_CN"
            fi
            openssl genrsa -des3 -passout pass:x -out /tmp/server.pass.key 4096
            openssl rsa -passin pass:x -in /tmp/server.pass.key -out "$DATA_DIR/certs/zulip.key"
            openssl req -new -nodes -subj "$ZULIP_CERTIFICATE_SUBJ" -key "$DATA_DIR/certs/zulip.key" -out /tmp/server.csr
            openssl x509 -req -days 365 -in /tmp/server.csr -signkey "$DATA_DIR/certs/zulip.key" -out "$DATA_DIR/certs/zulip.combined-chain.crt"
            rm -f /tmp/server.csr /tmp/server.pass.key
            echo "Certificates generation done."
        else
            echo "Certificates already exist. No need to generate them."
        fi
    fi
    if [ ! -e "$DATA_DIR/certs/zulip.key" ]; then
        echo "No zulip.key given in $DATA_DIR."
        return 1
    fi
    if [ ! -e "$DATA_DIR/certs/zulip.combined-chain.crt" ]; then
        echo "No zulip.combined-chain.crt given in $DATA_DIR."
        return 1
    fi
    ln -sfT "$DATA_DIR/certs/zulip.key" "/etc/ssl/private/zulip.key"
    ln -sfT "$DATA_DIR/certs/zulip.combined-chain.crt" "/etc/ssl/certs/zulip.combined-chain.crt"
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
CACHES = {
    'default': {
        'BACKEND':  'django.core.cache.backends.memcached.PyLibMCCache',
        'LOCATION': '$MEMCACHED_HOST:$MEMCACHED_HOST_PORT',
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
        local KEY="ZULIP_AUTH_BACKENDS_$AUTH_BACKEND_KEY"
        local AUTH_BACKEND_VAR="${!KEY}"
        if [ -z "$AUTH_BACKEND_VAR" ]; then
            echo "No authentication backend for key \"$AUTH_BACKEND_KEY\"."
            continue
        fi
        echo "Adding authentication backend \"$AUTH_BACKEND_KEY\"."
        echo "AUTHENTICATION_BACKENDS += ('zproject.backends.$AUTH_BACKEND_KEY',)" >> "$ZULIP_ZPROJECT_SETTINGS"
    done
    # Rabbitmq settings
    cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_HOST = '$RABBITMQ_HOST'
EOF
    if [ ! -z "$RABBITMQ_USERNAME" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_USERNAME = '$RABBITMQ_USERNAME'
EOF
    fi
    if [ ! -z "$RABBITMQ_PASS" ]; then
        cat >> "$ZULIP_ZPROJECT_SETTINGS" <<EOF
RABBITMQ_PASSWORD = '$RABBITMQ_PASS'
EOF
    fi
    sed -i "s~pika.ConnectionParameters('localhost',~pika.ConnectionParameters(settings.RABBITMQ_HOST,~g" "$ZULIP_CURRENT_DEPLOY/zerver/lib/queue.py"
    # Redis settings
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
REDIS_PORT = $REDIS_HOST_PORT
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
    unset SETTING_KEY
    if [ -z "$ZULIP_USER_EMAIL" ]; then
        echo "No zulip user email given."
        return 1
    fi
    if [ -z "$ZULIP_USER_DOMAIN" ]; then
        echo "No zulip user domain given."
        return 1
    fi
    if [ -z "$ZULIP_USER_PASS" ]; then
        echo "No zulip user password given."
        return 1
    fi
    if [ -z "$ZULIP_USER_FULLNAME" ]; then
        echo "No zulip user full name given. Defaulting to \"Zulip Docker\""
        export ZULIP_USER_FULLNAME="Zulip Docker"
    fi
}
managepy() {
    if [ -z "$1" ]; then
        echo "No command given for manage.py"
        return 1
    fi
    echo "Running manage.py ..."
    su zulip -c "/home/zulip/deployments/current/manage.py $*"
    return $?
}

case "$1" in
    manage.py)
    shift 1
    exec managepy "$@"
    exit $?
    ;;
    *)
    ;;
esac

if [ ! -d "/home/zulip/uploads" ]; then
    mkdir -p "/home/zulip/uploads"
fi
if [ -d "$DATA_DIR/uploads" ]; then
    rm -rf "/home/zulip/uploads"
else
    mkdir -p "$DATA_DIR/uploads"
    mv -f "/home/zulip/uploads" "$DATA_DIR/uploads"
fi
ln -sfT "$DATA_DIR/uploads" "/home/zulip/uploads"
chown zulip:zulip -R "$DATA_DIR/uploads"

echo "Generating and setting secrets ..."
if [ ! -e "$DATA_DIR/zulip-secrets.conf" ]; then
    # Generate the secrets
    /root/zulip/scripts/setup/generate_secrets.py
    mv -f "/etc/zulip/zulip-secrets.conf" "$DATA_DIR/zulip-secrets.conf"
fi
ln -sfT "$DATA_DIR/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
secretsSetup
echo "Secrets generated and set."
echo "Setting Zulip settings ..."
# Setup zulip settings
if ! zulipSetup; then
    echo "Zulip setup failed."
    exit 1
fi
echo "Zulip settings setup done."
echo "Configuring RabbitMQ ..."
# Configure rabbitmq server everytime because it could be a new one ;)
rabbitmqSetup
echo "RabbitMQ configured."
echo "Setting up database settings and server ..."
# setup database
databaseSetup
echo "Database setup done."
echo "Checking zulip config ..."
su zulip -c "/home/zulip/deployments/current/manage.py checkconfig"
if [ ! -e "$DATA_DIR/.initiated" ]; then
    echo "Initiating  Database ..."
    # Init database with something called data :D
    if ! databaseInitiation; then
        echo "Database initiation failed."
        exit 1
    fi
    echo "Database initiated."
    echo ""
    touch "$DATA_DIR/.initiated"
else
    rm -f /etc/supervisor/conf.d/zulip_postsetup.conf
fi
# If there's an "update" available, then "JUST DO IT!" - Shia Labeouf
if [ ! -e "$DATA_DIR/.zulip-$ZULIP_VERSION" ]; then
    echo "Starting zulip migration ..."
    if ! su zulip -c "/home/zulip/deployments/current/manage.py migrate"; then
        echo "Zulip migration failed."
        exit 1
    fi
    rm -rf "$DATA_DIR/.zulip-*"
    touch "$DATA_DIR/.zulip-$ZULIP_VERSION"
    echo "Zulip migration done."
fi
echo "Starting zulip using supervisor ..."
# Start supervisord
exec supervisord
