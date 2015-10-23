#!/bin/bash

if [ "$DEBUG" == "true" ] || [ "$DEBUG" == "True" ]; then
    set -x
    set -o functrace
fi
set -e

# Custom env variables
# DB
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_HOST_PORT="${DB_HOST_PORT:-5432}"
DB_USER="${DB_USER:-zulip}"
DB_ROOT_USER="${DB_ROOT_USER:-postgres}"
DB_ROOT_PASS="${DB_ROOT_PASS:-}"
DB_PASSWORD="${DB_PASSWORD:-zulip}"
DB_PASS="${DB_PASS:-$(echo $DB_PASSWORD)}"
DB_NAME="${DB_NAME:-zulip}"
DB_SCHEMA="${DB_SCHEMA:-zulip}"
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
ZULIP_USER_PASSWORD="${ZULIP_USER_PASSWORD:-zulip}"
export ZULIP_USER_PASS="${ZULIP_USER_PASS:-$(echo $ZULIP_USER_PASSWORD)}"
# Zulip certifcate parameters
ZULIP_AUTO_GENERATE_CERTS="${ZULIP_AUTO_GENERATE_CERTS:True}"
ZULIP_CERTIFICATE_SUBJ="${ZULIP_CERTIFICATE_SUBJ:-}"
ZULIP_CERTIFICATE_C="${ZULIP_CERTIFICATE_C:-US}"
ZULIP_CERTIFICATE_ST="${ZULIP_CERTIFICATE_ST:-Denial}"
ZULIP_CERTIFICATE_L="${ZULIP_CERTIFICATE_L:-Springfield}"
ZULIP_CERTIFICATE_O="${ZULIP_CERTIFICATE_O:-Dis}"
ZULIP_CERTIFICATE_CN="${ZULIP_CERTIFICATE_CN:-}"
# Zulip related settings
ZULIP_AUTH_BACKENDS="${ZULIP_AUTH_BACKENDS:-EmailAuthBackend}"
ZULIP_SECRETS_rabbitmq_password="${ZULIP_SECRETS_rabbitmq_password:-$(echo $RABBITMQ_PASS)}"
# Log2Zulip settings
LOG2ZULIP_ENABLED="False"
LOG2ZULIP_EMAIL=""
LOG2ZULIP_API_KEY=""
LOG2ZULIP_SITE=""
LOG2ZULIP_LOGFILES="/var/log/nginx/error.log"

# entrypoint.sh specific variables
ZULIP_CURRENT_DEPLOY="/home/zulip/deployments/current"
ZULIP_SETTINGS="/etc/zulip/settings.py"
ZPROJECT_SETTINGS="$ZULIP_CURRENT_DEPLOY/zproject/settings.py"

# BEGIN appRun functions
# === initialConfiguration ===
createDirectories() {
    if [ ! -d "$DATA_DIR/certs" ]; then
        mkdir -p "$DATA_DIR/certs"
    fi
}
linkDirectoriesToVolume() {
    if [ ! -d /home/zulip/uploads ]; then
        mkdir -p /home/zulip/uploads
    fi
    if [ ! -d "$DATA_DIR/uploads" ]; then
        mkdir -p "$DATA_DIR/uploads"
        mv -f /home/zulip/uploads "$DATA_DIR/uploads"
    else
        rm -rf /home/zulip/uploads
    fi
    ln -sfT "$DATA_DIR/uploads" /home/zulip/uploads
    chown zulip:zulip -R "$DATA_DIR/uploads"
}
setConfigurationValue() {
    if [ -z "$1" ]; then
        echo "No KEY given for setConfigurationValue."
        return 1
    fi
        if [ -z "$3" ]; then
            echo "No FILE given for setConfigurationValue."
            return 1
        fi
    local KEY="$1"
    local FILE="$3"
    local TYPE="$4"
    if [ -z "$TYPE" ]; then
        case "$2" in
            [Tt][Rr][Uu][Ee]|[Ff][Aa][Ll][Ss][Ee])
            local TYPE="bool"
            ;;
            *)
            local TYPE="string"
            ;;
        esac
    fi
    case "$TYPE" in
        emptyreturn)
        if [ -z "$2" ]; then
            return 0
        fi
        ;;
        literal)
        local VALUE="$VALUE"
        ;;
        bool|boolean|int|integer|array)
        local VALUE="$KEY = $VALUE"
        ;;
        string|*)
        local VALUE="$KEY = '${VALUE//\'/\'}'"
        ;;
    esac
    set +e
    # REGEX? FTW!
    echo "$(grep -v "$(grep -Pzo "#?$KEY*[ ]*=[ ]*(['\"].*['\"]$|[{(\[].*([})\}]$|\n(\n[}\}]$|.+\n)*)|.*$)" "$FILE")" "$FILE")" > "$FILE"
    if (($? > 0)); then
        echo "$VALUE" >> "$FILE"
        echo "Setting key \"$KEY\" with value \"$VALUE\"."
    fi
    set -e
}
configureCerts() {
    echo "Exectuing certificates configuration..."
    echo "==="
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
    if [ -e "$DATA_DIR/certs/zulip.key" ]; then
        ln -sfT "$DATA_DIR/certs/zulip.key" /etc/ssl/private/zulip.key
    fi
    if [ -e "$DATA_DIR/certs/zulip.combined-chain.crt" ]; then
        ln -sfT "$DATA_DIR/certs/zulip.combined-chain.crt" /etc/ssl/certs/zulip.combined-chain.crt
    fi
    if [ ! -e "$DATA_DIR/certs/zulip.key" ] && [ ! -e "$DATA_DIR/certs/zulip.combined-chain.crt" ]; then
        if [ ! -z "$ZULIP_AUTO_GENERATE_CERTS" ] && ([ "$ZULIP_AUTO_GENERATE_CERTS" == "True" ] || [ "$ZULIP_AUTO_GENERATE_CERTS" == "true" ]); then
            echo "ZULIP_AUTO_GENERATE_CERTS is true and no certs where found in $DATA_DIR/certs. Autogenerating certificates ..."
            if [ -z "$ZULIP_CERTIFICATE_SUBJ" ]; then
                if [ -z "$ZULIP_CERTIFICATE_CN" ]; then
                    if [ -z "$ZULIP_SETTINGS_EXTERNAL_HOST" ]; then
                        echo "Certificates generation failed. Missing ZULIP_CERTIFICATE_CN and as backup ZULIP_SETTINGS_EXTERNAL_HOST not given."
                        return 1
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
            echo "Certificate autogeneration succeeded."
        else
            echo "Certificates already exist. No need to generate them. Continuing."
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
    echo "==="
    echo "Certificates configuration succeeded."
}
secretsConfiguration() {
    echo "Setting Zulip secrets ..."
    echo "==="
    if [ ! -e "$DATA_DIR/zulip-secrets.conf" ]; then
        echo "Generating Zulip secrets ..."
        /root/zulip/scripts/setup/generate_secrets.py
        mv -f /etc/zulip/zulip-secrets.conf "$DATA_DIR/zulip-secrets.conf"
        echo "Zulip secrets generation succeeded."
    else
        echo "Zulip secrets already generated."
    fi
    ln -sfT "$DATA_DIR/zulip-secrets.conf" /etc/zulip/zulip-secrets.conf
    set +e
    local SECRETS=($(env | sed -nr "s/ZULIP_SECRETS_([A-Z_a-z-]*).*/\1/p"))
    for SECRET_KEY in "${SECRETS[@]}"; do
        local KEY="ZULIP_SECRETS_$SECRET_KEY"
        local SECRET_VAR="${!KEY}"
        if [ -z "$SECRET_VAR" ]; then
            echo "Empty secret for key \"$SECRET_KEY\"."
            continue
        fi
        grep -q "$SECRET_KEY" /etc/zulip/zulip-secrets.conf
        if (($? > 0)); then
            echo "Secret found for \"$SECRET_KEY\"."
            sed -i -r "s~#?${SECRET_KEY}[ ]*=[ ]*['\"]+.*['\"]+$~${SECRET_KEY} = '${SECRET_VAR}'~g" /etc/zulip/zulip-secrets.conf
            continue
        else
            echo "$SECRET_KEY = $SECRET_VAR" >> /etc/zulip/zulip-secrets.conf
        fi
    done
    set -e
    unset SECRET_KEY SECRET_VAR KEY
    echo "==="
    echo "Zulip secrets configuration succeeded."
}
databaseConfiguration() {
    echo "Setting database configuration ..."
    setConfigurationValue "from zerver.lib.db import TimeTrackingConnection" "" "$ZPROJECT_SETTINGS" "literal"
    VALUE="DATABASES = {
  'default': {
    'ENGINE': 'django.db.backends.postgresql_psycopg2',
    'NAME': '$DB_NAME',
    'USER': '$DB_USER',
    'PASSWORD': '$DB_PASS',
    'HOST': '$DB_HOST',
    'PORT': '$DB_HOST_PORT',
    'SCHEMA': '$DB_SCHEMA',
    'CONN_MAX_AGE': 600,
    'OPTIONS': {
        'connection_factory': TimeTrackingConnection,
        'sslmode': 'prefer',
    },
  },
}"
    setConfigurationValue "DATABASES" "$VALUE" "$ZPROJECT_SETTINGS" "array"
    sed -i "s~psycopg2.connect\(.*\)~psycopg2.connect(\"host=$DB_HOST port=$DB_HOST_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASS\")~g" /usr/local/bin/process_fts_updates
    echo "Database configuration succeeded."
}
cacheRatelimitConfiguration() {
    echo "Setting caches configuration ..."
    VALUE="CACHES = {
    'default': {
        'BACKEND':  'django.core.cache.backends.memcached.PyLibMCCache',
        'LOCATION': '$MEMCACHED_HOST:$MEMCACHED_HOST_PORT',
        'TIMEOUT':  $MEMCACHED_TIMEOUT
    },
    'database': {
        'BACKEND':  'django.core.cache.backends.db.DatabaseCache',
        'LOCATION':  'third_party_api_results',
        'TIMEOUT': 2000000000,
        'OPTIONS': {
            'MAX_ENTRIES': 100000000,
            'CULL_FREQUENCY': 10,
        }
    },
}"
    setConfigurationValue "CACHES" "$VALUE" "$ZPROJECT_SETTINGS" "array"
    echo "Caches configuration succeeded."
}
authenticationBackends() {
    echo "Activating authentication backends ..."
    echo "$ZULIP_AUTH_BACKENDS" | sed -n 1'p' | tr ',' '\n' | while read AUTH_BACKEND; do
        echo "AUTHENTICATION_BACKENDS += ('zproject.backends.${AUTH_BACKEND//\'/\'}',)" >> "$ZULIP_SETTINGS"
        echo "Adding authentication backend \"$AUTH_BACKEND\"."
    done
    echo "Authentication backend activation succeeded."
}
redisConfiguration() {
    echo "Setting redis configuration ..."
    setConfigurationValue "RATE_LIMITING" "$REDIS_RATE_LIMITING" "$ZPROJECT_SETTINGS" "bool"
    setConfigurationValue "REDIS_HOST" "$REDIS_HOST" "$ZPROJECT_SETTINGS"
    setConfigurationValue "REDIS_HOST_PORT" "$REDIS_HOST_PORT" "$ZPROJECT_SETTINGS" "int"
    echo "Redis configuration succeeded."
}
rabbitmqConfiguration() {
    echo "Setting rabbitmq configuration ..."
    setConfigurationValue "RABBITMQ_HOST" "$RABBITMQ_HOST" "$ZPROJECT_SETTINGS"
    sed -i "s~pika.ConnectionParameters('localhost',~pika.ConnectionParameters(settings.RABBITMQ_HOST,~g" "$ZULIP_CURRENT_DEPLOY/zerver/lib/queue.py"
    setConfigurationValue "RABBITMQ_USERNAME" "$RABBITMQ_USERNAME" "$ZPROJECT_SETTINGS"
    echo "Rabbitmq configuration succeeded."
}
camoConfiguration() {
    setConfigurationValue "CAMO_URI" "$CAMO_URI" "$ZPROJECT_SETTINGS" "emptyreturn"
}
zulipConfiguration() {
    echo "Executing Zulip configuration ..."
    echo "==="
    if [ ! -z "$ZULIP_CUSTOM_SETTINGS" ]; then
        echo -e "\n$ZULIP_CUSTOM_SETTINGS" >> "$ZPROJECT_SETTINGS"
    fi
    local SET_SETTINGS=($(env | sed -n -r "s/ZULIP_SETTINGS_([A-Z_]*).*/\1/p"))
    for SETTING_KEY in "${SET_SETTINGS[@]}"; do
        local KEY="ZULIP_SETTINGS_$SETTING_KEY"
        local SETTING_VAR="${!KEY}"
        if [ -z "$SETTING_VAR" ]; then
            echo "Empty var for key \"$SETTING_KEY\"."
            continue
        fi
        setConfigurationValue "$SETTING_KEY" "$SETTING_VAR" "$ZPROJECT_SETTINGS"
        echo "Set key \"$SETTING_KEY\"."
    done
    unset SETTING_KEY SETTING_VAR KEY
    if ! su zulip -c "/home/zulip/deployments/current/manage.py checkconfig"; then
        echo "Error in Zulip configuration."
        exit 1
    fi
    echo "==="
    echo "Zulip configuration succeeded."
}
log2zulipConfiguration() {
    echo "log2zulip is currently not fully implemented. Stay tuned."
    if [ "$LOG2ZULIP_ENABLED" != "True" ] || [ "$LOG2ZULIP_ENABLED" != "true" ]; then
        rm -f /etc/cron/conf.d/log2zulip
        return 0
    fi
    echo "Executing Log2Zulip configuration ..."
    echo "==="
    if ([ "$LOG2ZULIP_AUTO_CREATE" != "True" ] || [ "$LOG2ZULIP_AUTO_CREATE" != "true" ]) && [ ! -z "$LOG2ZULIP_EMAIL" ] && [ ! -z "$LOG2ZULIP_API_KEY" ] && [ ! -z "$LOG2ZULIP_SITE" ]; then
        sed -i "s/email = .*/email = $LOG2ZULIP_EMAIL/g" /etc/log2zulip.zuliprc
        sed -i "s/key = .*/key = $LOG2ZULIP_API_KEY/g" /etc/log2zulip.zuliprc
        sed -i "s/site = .*/site = $LOG2ZULIP_SITE/g" /etc/log2zulip.zuliprc
        LOGFILES="["
        echo "$LOG2ZULIP_LOGFILES" | sed -n 1'p' | tr ',' '\n' | while read LOG_FILE; do
            LOGFILES="$LOGFILES\"${LOG_FILE//\"/\"}\","
            echo "Adding log file \"$LOG_FILE\"."
        done
        echo "$(echo "$LOGFILES" | sed 's/,$//g')]" > /etc/log2zulip.conf
    fi
    echo "==="
    echo "Log2Zulip configuration succeeded."
}
initialConfiguration() {
    echo "=== Begin Initial Configuration Phase ==="
    secretsConfiguration
    configureCerts
    databaseConfiguration
    cacheRatelimitConfiguration
    authenticationBackends
    redisConfiguration
    rabbitmqConfiguration
    camoConfiguration
    zulipConfiguration
    log2zulipConfiguration
    echo "=== End Initial Configuration Phase ==="
}
# === bootstrappingEnvironment ===
waitingForDatabase() {
    export PGPASSWORD="$DB_PASS"
    local TIMEOUT=60
    echo "Waiting for database server to allow connections ..."
    while ! /usr/bin/pg_isready -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" -t 1 >/dev/null 2>&1
    do
        TIMEOUT=$(expr $TIMEOUT - 1)
        if [[ $TIMEOUT -eq 0 ]]; then
            echo "Could not connect to database server. Aborting ..."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
}
bootstrapDatabase() {
    echo "(Re)creating database structure ..."
    export PGPASSWORD="$DB_PASS"
    echo """
    CREATE USER zulip;
    ALTER ROLE zulip SET search_path TO zulip,public;
    CREATE DATABASE zulip OWNER=zulip;
    CREATE SCHEMA zulip AUTHORIZATION zulip;
    """ | psql -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" || :
    if [ ! -z "$DB_ROOT_USER" ] && [ ! -z "$DB_ROOT_PASS" ]; then
        echo "DB_ROOT_USER given, creating extension tsearch_extras"
        export PGPASSWORD="$DB_ROOT_PASS"
        echo "CREATE EXTENSION tsearch_extras SCHEMA zulip;" | \
        psql -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_ROOT_USER" "zulip" || :
        unset
    fi
    unset PGPASSWORD
    echo "Database structure recreated."
}
bootstrapRabbitMQ() {
    echo "RabbitMQ deleting user \"guest\"."
    rabbitmqctl -n "$RABBITMQ_HOST" delete_user guest || :
    echo "RabbitMQ adding user \"$RABBITMQ_USERNAME\"."
    rabbitmqctl -n "$RABBITMQ_HOST" add_user "$RABBITMQ_USERNAME" "$ZULIP_SECRETS_rabbitmq_password" || :
    echo "RabbitMQ setting user tags for \"$RABBITMQ_USERNAME\"."
    rabbitmqctl -n "$RABBITMQ_HOST" set_user_tags "$RABBITMQ_USERNAME" administrator || :
    echo "RabbitMQ setting permissions for user \"$RABBITMQ_USERNAME\"."
    rabbitmqctl -n "$RABBITMQ_HOST" set_permissions -p / "$RABBITMQ_USERNAME" '.*' '.*' '.*' || :
    echo "RabbitMQ bootstrap succeeded."
}
zulipFirstStartInit() {
    if [ -z "$FORCE_INIT" ] || [ -e "$DATA_DIR/.initiated" ]; then
        echo "First Start Init not needed."
        return 0
    fi
    echo "Executing Zulip first start init ..."
    echo "==="
    if ! su zulip -c "/home/zulip/deployments/current/manage.py migrate --noinput"; then
        RETURN_CODE=$?
        echo "==="
        echo "Zulip first start init failed in \"migrate --noinput\". with exit code $RETURN_CODE"
        exit $RETURN_CODE
    fi
    echo "Creating Zulip cache and third_party_api_results tables ..."
    if ! su zulip -c "/home/zulip/deployments/current/manage.py createcachetable third_party_api_results"; then
        RETURN_CODE=$?
        echo "==="
        echo "Zulip first start init failed in \"createcachetable third_party_api_results\" with exit code $RETURN_CODE."
        exit $RETURN_CODE
    fi
    echo "Initializing Zulip Voyager database ..."
    if ! su zulip -c "/home/zulip/deployments/current/manage.py initialize_voyager_db"; then
        RETURN_CODE=$?
        echo "==="
        echo "Zulip first start init failed in \"initialize_voyager_db\" with exit code $RETURN_CODE."
        exit $RETURN_CODE
    fi
    echo "==="
    echo "Zulip first start init sucessful."
}
zulipMigration() {
    if [ -e "$DATA_DIR/.zulip-$ZULIP_VERSION" ]; then
        echo "No Zulip migration needed. Continuing."
        return 0
    fi
    echo "Migrating Zulip to new version ..."
    echo "==="
    if ! su zulip -c "/home/zulip/deployments/current/manage.py migrate"; then
        RETURN_CODE=$?
        echo "==="
        echo "Zulip migration failed."
        exit $RETURN_CODE
    fi
    rm -rf "$DATA_DIR/.zulip-*"
    touch "$DATA_DIR/.zulip-$ZULIP_VERSION"
    echo "==="
    echo "Zulip migration succeeded."
}
bootstrappingEnvironment() {
    echo "=== Begin Bootstrap Phase ==="
    waitingForDatabase
    bootstrapDatabase
    bootstrapRabbitMQ
    zulipFirstStartInit
    zulipMigration
    echo "=== End Bootstrap Phase ==="
}
# END appRun functionss
appHelp() {
    echo "Available commands:"
    echo "> app:help     - Show this help menu and exit"
    echo "> app:version  - Container Zulip server version"
    echo "> app:managepy - Run Zulip's manage.py script"
    echo "> app:manage   - Create, Restore and manage backups of Zulip instances"
    echo "> app:run      - Run the Zulip server"
    echo "> [COMMAND]    - Run given command with arguments in shell"
}
appVersion() {
    echo "This container contains:"
    echo "> Zulip server $ZULIP_VERSION"
    echo "> Checksum: $ZULIP_CHECKSUM"
    exit 0
}
appManagePy() {
    COMMAND="$1"
    shift 1
    if [ -z "$COMMAND" ]; then
        echo "No command given for manage.py. Defaulting to \"shell\""
        COMMAND="shell"
    fi
    echo "Running manage.py ..."
    echo "==="
    su zulip -c "/home/zulip/deployments/current/manage.py $COMMAND $*"
    exit $?
}
appBackup() {
    echo "This function is coming soon, to your nearest docker-zulip entrypoint.sh ;)"
    exit 1
}
appRun() {
    createDirectories
    linkDirectoriesToVolume
    initialConfiguration
    bootstrappingEnvironment
    echo "Starting supervisor with \"/etc/supervisor/supervisor.conf\" ..."
    echo "==="
    exec supervisord -c /etc/supervisor/supervisor.conf
}

case "$1" in
    app:help)
        appHelp
    ;;
    app:version)
        appVersion
    ;;
    app:managepy)
        shift 1
        exec appManagePy "$@"
    ;;
    app:manage)
        appManage
    ;;
    app:run)
        appRun
    ;;
    *)
        if [[ -x $1 ]]; then
            $1
        else
            COMMAND="$1"
            if [[ -n $(which $COMMAND) ]] ; then
                shift 1
                $(which $COMMAND) "$@"
            else
                appHelp
            fi
        fi
    ;;
esac
exit 0
