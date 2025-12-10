#!/bin/bash

if [ "$DEBUG" = "true" ] || [ "$DEBUG" = "True" ]; then
    set -x
    set -o functrace
fi
set -e
set -u
shopt -s extglob

normalize_bool() {
    # Returns either "True" or "False", or possibly "None" if a third argument is given
    local varname="$1"
    local raw_value="${!varname:-}"
    local value="${raw_value,,}" # Convert to lowercase
    local default="${2-False}"   # Only default if not provided; explicit "" is a valid default
    local allow_none="${3:-}"

    case "$value" in
        true | enable | enabled | yes | y | 1 | on)
            echo "True"
            ;;
        false | disable | disabled | no | n | 0 | off)
            echo "False"
            ;;
        "")
            echo "$default"
            ;;
        *)
            if [ -n "$allow_none" ] && [ "$value" = "none" ]; then
                echo "None"
            else
                echo "WARNING: Invalid boolean ('$raw_value') for '$varname'; defaulting to $default" >&2
                echo "$default"
            fi
            ;;
    esac
}

## Settings

# PostgreSQL
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_HOST_PORT="${DB_HOST_PORT:-5432}"
DB_NAME="${DB_NAME:-zulip}"
DB_USER="${DB_USER:-zulip}"

# RabbitMQ
SETTING_RABBITMQ_HOST="${SETTING_RABBITMQ_HOST:-127.0.0.1}"

# Redis
SETTING_REDIS_HOST="${SETTING_REDIS_HOST:-127.0.0.1}"

# Memcached
SETTING_MEMCACHED_LOCATION="${SETTING_MEMCACHED_LOCATION:-127.0.0.1:11211}"

# Nginx and HTTP(S) settings
NGINX_WORKERS="${NGINX_WORKERS:-2}"
NGINX_MAX_UPLOAD_SIZE="${NGINX_MAX_UPLOAD_SIZE:-80m}"
LOADBALANCER_IPS="${LOADBALANCER_IPS:-}"
TRUST_GATEWAY_IP="$(normalize_bool TRUST_GATEWAY_IP)"
CERTIFICATES="${CERTIFICATES:-}"

# Outgoing proxy settings
PROXY_ALLOW_ADDRESSES="${PROXY_ALLOW_ADDRESSES:-}"
PROXY_ALLOW_RANGES="${PROXY_ALLOW_RANGES:-}"

# Core Zulip settings
ZULIP_AUTH_BACKENDS="${ZULIP_AUTH_BACKENDS:-EmailAuthBackend}"
QUEUE_WORKERS_MULTIPROCESS="$(normalize_bool QUEUE_WORKERS_MULTIPROCESS '')"

# Configuration controls
ZULIP_RUN_POST_SETUP_SCRIPTS="$(normalize_bool ZULIP_RUN_POST_SETUP_SCRIPTS True)"
ZULIP_CUSTOM_SETTINGS="${ZULIP_CUSTOM_SETTINGS:-}"
MANUAL_CONFIGURATION="$(normalize_bool MANUAL_CONFIGURATION)"
LINK_SETTINGS_TO_DATA="$(normalize_bool LINK_SETTINGS_TO_DATA)"

# Auto backup settings
AUTO_BACKUP_ENABLED="$(normalize_bool AUTO_BACKUP_ENABLED True)"
AUTO_BACKUP_INTERVAL="${AUTO_BACKUP_INTERVAL:-30 3 * * *}"

# All of the above config vars, minus SETTING_ ones.
our_vars=(
    DATA_DIR
    DB_HOST DB_HOST_PORT DB_NAME DB_USER
    NGINX_WORKERS NGINX_MAX_UPLOAD_SIZE LOADBALANCER_IPS TRUST_GATEWAY_IP
    CERTIFICATES PROXY_ALLOW_ADDRESSES PROXY_ALLOW_RANGES
    ZULIP_AUTH_BACKENDS QUEUE_WORKERS_MULTIPROCESS
    ZULIP_RUN_POST_SETUP_SCRIPTS ZULIP_CUSTOM_SETTINGS
    MANUAL_CONFIGURATION LINK_SETTINGS_TO_DATA
    AUTO_BACKUP_ENABLED AUTO_BACKUP_INTERVAL
)
standard_vars=(
    HOSTNAME PWD HOME LANG SHLVL PATH _
)
failure=0
for env_var in $(env -0 | cut -z -f1 -d= | tr '\0' '\n' | grep -vE '^(SECRET|SETTING|KUBERNETES)_'); do
    if [ "${env_var^^}" != "$env_var" ]; then
        # Skip if not all upper-case
        :
    elif echo " ${our_vars[*]} ${standard_vars[*]} " | grep -q " $env_var "; then
        # Skip if normal config var or shell variable
        :
    elif grep -Eq "\b$env_var\b" /home/zulip/deployments/current/zproject/{default_settings,prod_settings_template}.py; then
        echo "WARNING: Unexpected environment variable '$env_var'; did you mean SETTING_$env_var ?"
        failure=1
    fi
done
if [ "$failure" = "1" ]; then
    echo
fi

# BEGIN appRun functions
# === initialConfiguration ===
prepareDirectories() {
    mkdir -p "$DATA_DIR" "$DATA_DIR/backups" "$DATA_DIR/uploads" "$DATA_DIR/certs/manual"
    if [ "${CERTIFICATES}" = "certbot" ]; then
        if [ -d "$DATA_DIR/certs/letsencrypt" ]; then
            echo "Linking letsencrypt folder ..."
            rm -rf /etc/letsencrypt/{accounts,archive,live,renewal}
        else
            echo "Preparing letsencrypt folder ..."
            mkdir "$DATA_DIR/certs/letsencrypt"
            mkdir -p /etc/letsencrypt/{accounts,archive,live,renewal}/
            mv /etc/letsencrypt/{accounts,archive,live,renewal}/ "$DATA_DIR/certs/letsencrypt/"
        fi
        ln -ns "$DATA_DIR/certs/letsencrypt/"{accounts,archive,live,renewal}/ /etc/letsencrypt/
    fi
    echo "Preparing and linking the uploads folder ..."
    rm -rf /home/zulip/uploads
    ln -sfT "$DATA_DIR/uploads" /home/zulip/uploads
    chown zulip:zulip -R "$DATA_DIR/uploads"
    # Link settings folder
    if [ "$LINK_SETTINGS_TO_DATA" = "True" ]; then
        # Create settings directories
        if [ ! -d "$DATA_DIR/etc-zulip" ]; then
            if [ -d "$DATA_DIR/settings/etc-zulip" ]; then
                # Migrate older settings/etc-zulip/
                echo "Migrating old $DATA_DIR/settings/etc-zulip to $DATA_DIR/etc-zulip"
                mv "$DATA_DIR/settings/etc-zulip" "$DATA_DIR/etc-zulip"
                rmdir "$DATA_DIR/settings" || true
            else
                if [ -f "$DATA_DIR/zulip-secrets.conf" ]; then
                    # A non-LINK_SETTINGS_TO_DATA config; move the actual
                    # secrets file into /etc/zulip/ and let the /etc/zulip
                    # copy-and-symlink handle backing it up.
                    echo "Migrating old $DATA_DIR/zulip-secrets.conf to $DATA_DIR/etc-zulip/zulip-secrets.conf"
                    mv -f "$DATA_DIR/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
                fi
                mkdir -p "$DATA_DIR/etc-zulip"
                # The trailing "." means that all contents are copied, not the directory
                cp -a /etc/zulip/. "$DATA_DIR/etc-zulip/"
                find /etc/zulip "$DATA_DIR/etc-zulip" -ls
            fi
        fi
        # Link /etc/zulip/ settings folder
        rm -rf /etc/zulip
        ln -sfT "$DATA_DIR/etc-zulip" /etc/zulip
    fi
    echo "Prepared and linked the uploads directory."
}
setConfigurationValue() {
    if [ -z "$1" ]; then
        echo "No KEY given for setConfigurationValue."
        return 1
    fi
    local KEY="$1"
    local VALUE
    local TYPE="$3"
    if [ -z "$TYPE" ]; then
        case "$2" in
            [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee] | [Nn]one)
                TYPE="bool"
                ;;
            +([0-9]))
                TYPE="integer"
                ;;
            [\[\(]*[\]\)])
                TYPE="array"
                ;;
            *)
                TYPE="string"
                ;;
        esac
    fi
    case "$TYPE" in
        literal)
            VALUE="$1"
            ;;
        bool)
            # Note that if any settings were explicitly set as type
            # "bool" (which none are at current), this would provide a
            # slightly confusing error message with "PROVIDED_SETTING"
            # in it, rather than the actual setting name.
            # shellcheck disable=SC2034
            local PROVIDED_SETTING="$2"
            VALUE="$KEY = $(normalize_bool PROVIDED_SETTING False allow_none)"
            ;;
        integer | array)
            VALUE="$KEY = $2"
            ;;
        string)
            VALUE="$KEY = '${2//\'/\'}'"
            ;;
        *)
            echo "WARNING: Unknown type '$TYPE' for '$KEY' -- treating as string." >&2
            VALUE="$KEY = '${2//\'/\'}'"
            ;;
    esac
    echo "$VALUE" >>/etc/zulip/settings.py
    echo "Setting key \"$KEY\", type \"$TYPE\"."
}
nginxConfiguration() {
    echo "Executing nginx configuration ..."
    sed -i "s/worker_processes .*/worker_processes $NGINX_WORKERS;/g" /etc/nginx/nginx.conf
    sed -i "s/client_max_body_size .*/client_max_body_size $NGINX_MAX_UPLOAD_SIZE;/g" /etc/nginx/nginx.conf
    echo "Nginx configuration succeeded."
}
puppetConfiguration() {
    echo "Executing puppet configuration ..."

    if [ "$CERTIFICATES" == "" ]; then
        echo "Disabling https in nginx."
        crudini --set /etc/zulip/zulip.conf application_server http_only true
    fi
    if [ "$QUEUE_WORKERS_MULTIPROCESS" == "True" ]; then
        echo "Setting queue workers to run in multiprocess mode ..."
        crudini --set /etc/zulip/zulip.conf application_server queue_workers_multiprocess true
    elif [ "$QUEUE_WORKERS_MULTIPROCESS" == "False" ]; then
        echo "Setting queue workers to run in multithreaded mode ..."
        crudini --set /etc/zulip/zulip.conf application_server queue_workers_multiprocess false
    fi

    if [ "$TRUST_GATEWAY_IP" == "True" ]; then
        local GATEWAY_IP
        GATEWAY_IP=$(ip route | grep default | awk '{print $3}')
        echo "Trusting local network gateway $GATEWAY_IP"
        LOADBALANCER_IPS="${LOADBALANCER_IPS:+$LOADBALANCER_IPS,}$GATEWAY_IP"
    fi
    if [ -n "$LOADBALANCER_IPS" ]; then
        echo "Setting IPs for load balancer"
        crudini --set /etc/zulip/zulip.conf loadbalancer ips "${LOADBALANCER_IPS}"
    fi

    if [ -n "$PROXY_ALLOW_ADDRESSES" ]; then
        echo "Setting outgoing proxy allowed private IPs"
        crudini --set /etc/zulip/zulip.conf http_proxy allow_addresses "${PROXY_ALLOW_ADDRESSES}"
    fi
    if [ -n "$PROXY_ALLOW_RANGES" ]; then
        echo "Setting outgoing proxy allowed private IP ranges"
        crudini --set /etc/zulip/zulip.conf http_proxy allow_ranges "${PROXY_ALLOW_RANGES}"
    fi

    if [ "$DB_NAME" != "zulip" ]; then
        echo "Setting database name to $DB_NAME"
        crudini --set /etc/zulip/zulip.conf postgresql database_name "$DB_NAME"
    fi

    if [ "$DB_USER" != "zulip" ]; then
        echo "Setting database user to $DB_USER"
        crudini --set /etc/zulip/zulip.conf postgresql database_user "$DB_USER"
    fi

    /home/zulip/deployments/current/scripts/zulip-puppet-apply -f
}
waitAndRunSetupCertbot() {
    # This is run backgrounded.
    echo "Waiting for nginx to come online before generating certbot certificate ..."
    while ! curl -sk "$SETTING_EXTERNAL_HOST" >/dev/null 2>&1; do
        sleep 1
    done

    echo "Generating LetsEncrypt/certbot certificate ..."

    # Overwrite the nginx hook to use supervisorctl
    cat <<EOF >/etc/letsencrypt/renewal-hooks/deploy/050-nginx.sh
#!/bin/env bash
supervisorctl signal HUP nginx
EOF

    # Accept the terms of service automatically.
    /home/zulip/deployments/current/scripts/setup/setup-certbot \
        --agree-tos \
        --email="$SETTING_ZULIP_ADMINISTRATOR" \
        -- \
        "$SETTING_EXTERNAL_HOST"

    echo "LetsEncrypt cert generated."
}
configureCerts() {
    if [ "$CERTIFICATES" == "" ]; then
        echo "No certificates will be installed; HTTP-only serving configured."
        rm -f /etc/ssl/private/zulip.key
        rm -f /etc/ssl/certs/zulip.combined-chain.crt
        return
    elif [ "$CERTIFICATES" == "manual" ]; then
        if [ ! -e "$DATA_DIR/certs/manual/zulip.key" ]; then
            echo "SSL private key zulip.key is not present in $DATA_DIR/certs/"
            echo "Manual certificate configuration failed."
            exit 1
        fi
        if [ ! -e "$DATA_DIR/certs/manual/zulip.combined-chain.crt" ]; then
            echo "SSL public key zulip.combined-chain.crt is not present in $DATA_DIR/certs/"
            echo "Manual certificate configuration failed."
            exit 1
        fi
        echo "Using manually-provided certificates in $DATA_DIR/certs/"
        ln -sfT "$DATA_DIR/certs/manual/zulip.key" /etc/ssl/private/zulip.key
        ln -sfT "$DATA_DIR/certs/manual/zulip.combined-chain.crt" /etc/ssl/certs/zulip.combined-chain.crt
        return
    elif [ "$CERTIFICATES" == "certbot" ]; then
        echo "Scheduling LetsEncrypt cert generation ..."
        # This certbot run cannot start until nginx is up, which this
        # process will do later under supervisor.  This guarantees
        # there is no race between the symlinking below, and certbot's
        # own symlinking later, once it potentially gets a new cert.
        waitAndRunSetupCertbot &

        le_dir="$DATA_DIR/certs/letsencrypt/live/$SETTING_EXTERNAL_HOST/"
        if [ -d "$le_dir" ] && [ -f "$le_dir/privkey.pem" ] && [ -f "$le_dir/fullchain.pem" ]; then
            echo "Using existing Lets Encrypt certificate."
            export ZULIP_DOMAIN="$SETTING_EXTERNAL_HOST"
            /etc/letsencrypt/renewal-hooks/deploy/020-symlink.sh
            return
        fi
        # We fall through and generate and use self-signed
        # certificates so nginx has something to use until we can
        # complete the certbot challenge.
    elif [ "$CERTIFICATES" == "self-signed" ]; then
        # Fall through to the below
        :
    else
        echo "Unknown value for CERTIFICATES: $CERTIFICATES"
        echo "Valid values are:"
        echo "  (empty)"
        echo "    HTTP-only serving"
        echo "  manual"
        echo "    Place certificates in data/certs/manual/zulip.key and zulip.combined-chain.crt"
        echo "  letsencrypt"
        echo "    Ensure that http://$SETTING_EXTERNAL_HOST is externally-accessible"
        echo "  self-signed"
        echo "    Generates a self-signed certificate"
        exit 1
    fi

    self_signed_dir="$DATA_DIR/certs/self-signed/"
    if [ -f "$self_signed_dir/zulip.key" ] && [ -f "$self_signed_dir/zulip.combined-chain.crt" ]; then
        echo "Using existing self-signed certificates in $self_signed_dir"
    else
        echo "Generating self-signed certificates..."
        mkdir -p "$self_signed_dir"
        /home/zulip/deployments/current/scripts/setup/generate-self-signed-cert "$SETTING_EXTERNAL_HOST"
        mv /etc/ssl/private/zulip.key "$self_signed_dir"
        mv /etc/ssl/certs/zulip.combined-chain.crt "$self_signed_dir"
    fi
    ln -sfT "$self_signed_dir/zulip.key" /etc/ssl/private/zulip.key
    ln -sfT "$self_signed_dir/zulip.combined-chain.crt" /etc/ssl/certs/zulip.combined-chain.crt
}
secretsConfiguration() {
    echo "Setting Zulip secrets ..."
    if [ "$LINK_SETTINGS_TO_DATA" = "True" ]; then
        # /etc/zulip is a symlink, and we update or create /etc/zulip/zulip-secrets.conf as usual
        :
    elif [ -e "$DATA_DIR/zulip-secrets.conf" ]; then
        # We have a previous secrets file; symlink it into place, then update it as needed
        ln -nsf "$DATA_DIR/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
    elif [ -e "$DATA_DIR/etc-zulip/zulip-secrets.conf" ]; then
        # This was _previously_ a LINK_SETTINGS_TO_DATA deploy; link to that.
        ln -nsf "$DATA_DIR/etc-zulip/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
    elif [ -e "/etc/zulip/zulip-secrets.conf" ]; then
        # Move into $DATA_DIR whatever was somehow in /etc/zulip/zulip-secrets.conf
        mv /etc/zulip/zulip-secrets.conf "$DATA_DIR/zulip-secrets.conf"
        ln -nsf "$DATA_DIR/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
    else
        # Fresh install; make an empty file to symlink into place, so generate_secrets can write to it.
        touch "$DATA_DIR/zulip-secrets.conf"
        ln -nsf "$DATA_DIR/zulip-secrets.conf" "/etc/zulip/zulip-secrets.conf"
    fi
    chmod 640 /etc/zulip/zulip-secrets.conf
    /root/zulip/scripts/setup/generate_secrets.py --production
    local key
    for key in "${!SECRETS_@}"; do
        [[ "$key" == SECRETS_*([0-9A-Z_a-z-]) ]] || continue
        local SECRET_KEY="${key#SECRETS_}"
        local SECRET_VAR="${!key}"
        if [[ "$SECRET_KEY" == *"_FILE" ]]; then
            SECRET_VAR="$(cat "$SECRET_VAR")"
            SECRET_KEY="${SECRET_KEY%_FILE}"
        fi
        if [ -z "$SECRET_VAR" ]; then
            echo "Empty secret for key \"$SECRET_KEY\"."
        elif [[ "$SECRET_VAR" =~ $'\n' ]]; then
            echo "ERROR: Secret \"$SECRET_KEY\" contains a newline!"
            exit 1
        fi
        echo "Setting $SECRET_KEY from environment variable $key"
        crudini --set "/etc/zulip/zulip-secrets.conf" "secrets" "${SECRET_KEY}" "${SECRET_VAR}"
    done
    # Secrets detected in /run/secrets/ override those via env vars
    shopt -s nullglob
    local secrets_path
    for secrets_path in /run/secrets/zulip__*; do
        local secrets_filename
        secrets_filename="$(basename "$secrets_path")"
        local SECRET_KEY="${secrets_filename#zulip__}"
        local SECRET_VAR
        SECRET_VAR="$(cat "$secrets_path")"
        if [ -z "$SECRET_VAR" ]; then
            echo "Empty secret for key \"$SECRET_KEY\"."
        elif [[ "$SECRET_VAR" =~ $'\n' ]]; then
            echo "ERROR: Secret \"$SECRET_KEY\" contains a newline!"
            exit 1
        fi
        echo "Setting $SECRET_KEY from secret in $secrets_path"
        crudini --set "/etc/zulip/zulip-secrets.conf" "secrets" "${SECRET_KEY}" "${SECRET_VAR}"
    done
    echo "Zulip secrets configuration succeeded."
}
databaseConfiguration() {
    echo "Setting database configuration ..."
    setConfigurationValue "REMOTE_POSTGRES_HOST" "$DB_HOST" "string"
    setConfigurationValue "REMOTE_POSTGRES_PORT" "$DB_HOST_PORT" "integer"
    if [ -z "${SETTING_REMOTE_POSTGRES_SSLMODE:-}" ]; then
        # We do this defaulting here, so that we don't false-positive the "you
        # used a SETTING_" for MANUAL_CONFIGURATION deploys.
        setConfigurationValue "REMOTE_POSTGRES_SSLMODE" "prefer" "string"
    fi
    # The password will be set in secretsConfiguration
    echo "Database configuration succeeded."
}
authenticationBackends() {
    echo "Activating authentication backends ..."
    local FIRST=true
    local auth_backends
    IFS=, read -r -a auth_backends <<<"$ZULIP_AUTH_BACKENDS"
    local AUTH_BACKEND
    for AUTH_BACKEND in "${auth_backends[@]}"; do
        if [ "$FIRST" = true ]; then
            setConfigurationValue "AUTHENTICATION_BACKENDS" "('zproject.backends.${AUTH_BACKEND//\'/\'}',)" "array"
            FIRST=false
        else
            setConfigurationValue "AUTHENTICATION_BACKENDS += ('zproject.backends.${AUTH_BACKEND//\'/\'}',)" "" "literal"
        fi
        echo "Adding authentication backend \"$AUTH_BACKEND\"."
    done
    echo "Authentication backend activation succeeded."
}
zulipConfiguration() {
    echo "Executing Zulip configuration ..."
    if [ -n "$ZULIP_CUSTOM_SETTINGS" ]; then
        echo -e "\n$ZULIP_CUSTOM_SETTINGS" >>/etc/zulip/settings.py
    fi
    local key
    for key in "${!SETTING_@}"; do
        [[ "$key" == SETTING_*([0-9A-Za-z_]) ]] || continue
        local setting_key="${key#SETTING_}"
        local setting_var="${!key}"
        local type=""
        if [ -z "$setting_var" ]; then
            echo "WARNING: Empty var for key \"$setting_key\", skipping."
            continue
        fi
        # Zulip settings.py / zproject specific overrides here
        if [ "$setting_key" = "AUTH_LDAP_CONNECTION_OPTIONS" ] \
            || [ "$setting_key" = "AUTH_LDAP_GLOBAL_OPTIONS" ] \
            || [ "$setting_key" = "AUTH_LDAP_USER_SEARCH" ] \
            || [ "$setting_key" = "AUTH_LDAP_GROUP_SEARCH" ] \
            || [ "$setting_key" = "AUTH_LDAP_REVERSE_EMAIL_SEARCH" ] \
            || [ "$setting_key" = "AUTH_LDAP_USER_ATTR_MAP" ] \
            || [ "$setting_key" = "AUTH_LDAP_USER_FLAGS_BY_GROUP" ] \
            || [ "$setting_key" = "AUTH_LDAP_GROUP_TYPE" ] \
            || [ "$setting_key" = "AUTH_LDAP_ADVANCED_REALM_ACCESS_CONTROL" ] \
            || [ "$setting_key" = "LDAP_SYNCHRONIZED_GROUPS_BY_REALM" ] \
            || [ "$setting_key" = "SOCIAL_AUTH_OIDC_ENABLED_IDPS" ] \
            || [ "$setting_key" = "SOCIAL_AUTH_SAML_ENABLED_IDPS" ] \
            || [ "$setting_key" = "SOCIAL_AUTH_SAML_ORG_INFO" ] \
            || [ "$setting_key" = "SOCIAL_AUTH_SYNC_ATTRS_DICT" ] \
            || { [ "$setting_key" = "LDAP_APPEND_DOMAIN" ] && [ "$setting_var" = "None" ]; } \
            || [ "$setting_key" = "SCIM_CONFIG" ] \
            || [ "$setting_key" = "SECURE_PROXY_SSL_HEADER" ] \
            || [[ "$setting_key" = "CSRF_"* ]] \
            || [ "$setting_key" = "REALM_HOSTS" ] \
            || [ "$setting_key" = "ALLOWED_HOSTS" ]; then
            type="array"
        fi
        if [ "$setting_key" = "EMAIL_HOST_USER" ] \
            || [ "$setting_key" = "EMAIL_HOST_PASSWORD" ] \
            || [ "$setting_key" = "EXTERNAL_HOST" ]; then
            type="string"
        fi
        setConfigurationValue "$setting_key" "$setting_var" "$type"
    done
    echo "Zulip configuration succeeded."
}
autoBackupConfiguration() {
    if [ "$AUTO_BACKUP_ENABLED" != "True" ]; then
        rm -f /etc/cron.d/autobackup
        echo "Auto backup is disabled. Continuing."
        return 0
    fi
    printf 'MAILTO=""\n%s cd /;/sbin/entrypoint.sh app:backup\n' "$AUTO_BACKUP_INTERVAL" >/etc/cron.d/autobackup
    echo "Auto backup enabled."
}
waitingForDatabase() {
    local TIMEOUT=60
    echo "Waiting for database server to allow connections ..."
    local PGPASSWORD
    PGPASSWORD="$(crudini --get /etc/zulip/zulip-secrets.conf secrets postgres_password)"
    while ! PGPASSWORD="$PGPASSWORD" /usr/bin/pg_isready -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" -t 1 >/dev/null 2>&1; do
        if ! ((TIMEOUT--)); then
            echo "Could not connect to database server. Exiting."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
}
zulipMigration() {
    echo "Running new database migrations..."
    set +e
    local RETURN_CODE=0
    su zulip -c "/home/zulip/deployments/current/manage.py migrate --noinput"
    RETURN_CODE=$?
    if [[ $RETURN_CODE != 0 ]]; then
        echo "Zulip migration failed with exit code $RETURN_CODE. Exiting."
        exit $RETURN_CODE
    fi
    set -e
    su zulip -c "/home/zulip/deployments/current/manage.py createcachetable third_party_api_results"
    echo "Database migrations completed."
}
runPostSetupScripts() {
    echo "Post setup scripts execution ..."
    if [ "$ZULIP_RUN_POST_SETUP_SCRIPTS" != "True" ]; then
        echo "Not running post setup scripts. ZULIP_RUN_POST_SETUP_SCRIPTS isn't true."
        return 0
    fi
    if [ ! -d "$DATA_DIR/post-setup.d/" ]; then
        echo "No post-setup.d folder found. Continuing."
        return 0
    fi
    if [ ! "$(ls "$DATA_DIR/post-setup.d/")" ]; then
        echo "No post setup scripts found in \"$DATA_DIR/post-setup.d/\"."
        return 0
    fi
    set +e
    for file in "$DATA_DIR"/post-setup.d/*; do
        if [ -x "$file" ]; then
            echo "Executing \"$file\" ..."
            bash -c "$file"
            echo "Executed \"$file\". Return code $?."
        else
            echo "Permissions denied for \"$file\". Please check the permissions. Exiting."
            exit 1
        fi
    done
    set -e
    echo "Post setup scripts execution succeeded."
}
initialConfiguration() {
    echo "=== Begin Initial Configuration Phase ==="
    prepareDirectories
    local root_path="/etc/zulip"
    if [ "$LINK_SETTINGS_TO_DATA" = "True" ]; then
        root_path="/data/etc-zulip"
    fi
    if [ "$MANUAL_CONFIGURATION" = "True" ]; then
        # We need to validate zulip.conf before we can run puppet
        if [ ! -f "/etc/zulip/zulip.conf" ]; then
            echo "ERROR: $root_path/zulip.conf does not exist!"
            exit 1
        elif ! sudo -u zulip test -r "/etc/zulip/zulip.conf"; then
            echo "ERROR: $root_path/zulip.conf is not readable by the zulip user (UID $(id -u zulip))"
            exit 1
        elif [ ! -s "/etc/zulip/zulip.conf" ]; then
            echo "ERROR: $root_path/zulip.conf is empty"
            exit 1
        fi
    fi
    puppetConfiguration
    nginxConfiguration
    configureCerts
    if [ "$MANUAL_CONFIGURATION" = "False" ]; then
        # Start with the settings template file.
        cp -a /home/zulip/deployments/current/zproject/prod_settings_template.py /etc/zulip/settings.py
        databaseConfiguration
        secretsConfiguration
        authenticationBackends
        zulipConfiguration
    else
        # Provide some defaults, and check that the configuration will work
        bootstrapped_from_env=0
        if [ ! -f "/etc/zulip/settings.py" ] || [ ! -s "/etc/zulip/settings.py" ]; then
            cp -a /home/zulip/deployments/current/zproject/prod_settings_template.py /etc/zulip/settings.py
            # This first time, pull from SETTING_ if provided.
            databaseConfiguration
            authenticationBackends
            zulipConfiguration
            bootstrapped_from_env=1
        elif ! sudo -u zulip test -r "/etc/zulip/settings.py"; then
            echo "ERROR: $root_path/settings.py is not readable by the zulip user (UID $(id -u zulip))"
            ls -l /etc/zulip/
            exit 1
        fi
        secretsConfiguration
        setting_envs=$(env -0 | cut -z -f1 -d= | tr '\0' '\n' | grep -E '^SETTING_' || true)
        if [ "$bootstrapped_from_env" = "1" ]; then
            if [ -n "$setting_envs" ] || [ "$ZULIP_AUTH_BACKENDS" != "EmailAuthBackend" ]; then
                echo
                echo "WARNING: Bootstrapping initial MANUAL_CONFIGURATION from environment variables."
            else
                echo
                echo "WARNING: Created a default $root_path/settings.py"
            fi
        else
            if [ -n "$setting_envs" ]; then
                echo
                echo "WARNING: SETTING_ environment variables detected; with MANUAL_CONFIGURATION set,"
                echo "         these will have no effect:"
                echo "$setting_envs"
            fi
            if [ "$ZULIP_AUTH_BACKENDS" != "EmailAuthBackend" ]; then
                echo
                echo "WARNING: ZULIP_AUTH_BACKENDS environment variable set; with MANUAL_CONFIGURATION set,"
                echo "         it will have no effect."
            fi
        fi
    fi
    if ! su zulip -c "/home/zulip/deployments/current/manage.py check"; then
        echo "Error in the Zulip configuration. Exiting."
        exit 1
    fi
    autoBackupConfiguration
    waitingForDatabase
    zulipMigration
    runPostSetupScripts
    echo "=== End Initial Configuration Phase ==="
}
# === bootstrappingEnvironment ===
# END appRun functions
# BEGIN app functions
appRun() {
    initialConfiguration
    echo "=== Begin Run Phase ==="
    echo "Starting Zulip using supervisor with \"/etc/supervisor/supervisord.conf\" config ..."
    echo ""
    unset HOME # avoid propagating HOME=/root to subprocesses not running as root
    exec supervisord -n -c "/etc/supervisor/supervisord.conf" -u root
}
appInit() {
    echo "=== Running initial setup ==="
    initialConfiguration
}
appManagePy() {
    local COMMAND="$1"
    shift 1
    if [ -z "$COMMAND" ]; then
        echo "No command given for manage.py. Defaulting to \"shell\"."
        COMMAND="shell"
    fi
    echo "Running manage.py ..."
    set +e
    exec su zulip -c "/home/zulip/deployments/current/manage.py $(printf '%q ' "$COMMAND" "$@")"
}
appBackup() {
    echo "Starting backup process ..."
    local TIMESTAMP
    TIMESTAMP=$(date -u -Iseconds | tr ':' '_')
    if [ -d "/tmp/backup-$TIMESTAMP" ]; then
        echo "Temporary backup folder for \"$TIMESTAMP\" already exists. Aborting."
        echo "Backup process failed. Exiting."
        exit 1
    fi
    local BACKUP_FOLDER="/tmp/backup-$TIMESTAMP"
    mkdir -p "$BACKUP_FOLDER"
    waitingForDatabase
    pg_dump -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" "$DB_NAME" >"$BACKUP_FOLDER/database-postgres.sql"
    tar -zcvf "$DATA_DIR/backups/backup-$TIMESTAMP.tar.gz" "$BACKUP_FOLDER/"
    rm -r "${BACKUP_FOLDER:?}/"
    echo "Backup process succeeded."
    exit 0
}
appRestore() {
    echo "Starting restore process ..."
    if [ -z "$(ls -A "$DATA_DIR/backups/")" ]; then
        echo "No backups to restore found in \"$DATA_DIR/backups/\"."
        echo "Restore process failed. Exiting."
        exit 1
    fi
    while true; do
        local backups=("$DATA_DIR"/backups/*)
        printf '|-> %s\n' "${backups[@]#"$DATA_DIR"/backups/}"
        echo "Please enter backup filename (full filename with extension): "
        read -r BACKUP_FILE
        if [ -z "$BACKUP_FILE" ]; then
            echo "Empty filename given. Please try again."
            echo ""
            continue
        fi
        if [ ! -e "$DATA_DIR/backups/$BACKUP_FILE" ]; then
            echo "File \"$BACKUP_FILE\" not found. Please try again."
            echo ""
        fi
        break
    done
    echo "File \"$BACKUP_FILE\" found."
    echo ""
    echo "==============================================================="
    echo "!! WARNING !! Your current data will be deleted!"
    echo "!! WARNING !! YOU HAVE BEEN WARNED! You can abort with \"CTRL+C\"."
    echo "!! WARNING !! Waiting 10 seconds before continuing ..."
    echo "==============================================================="
    echo ""
    local TIMEOUT
    for TIMEOUT in {10..1}; do
        echo "$TIMEOUT"
        sleep 1
    done
    echo "!! WARNING !! Starting restore process ... !! WARNING !!"
    waitingForDatabase
    tar -zxvf "$DATA_DIR/backups/$BACKUP_FILE" -C /tmp
    psql -h "$DB_HOST" -p "$DB_HOST_PORT" -U "$DB_USER" "$DB_NAME" <"/tmp/$(basename "$BACKUP_FILE" | cut -d. -f1)/database-postgres.sql"
    rm -r "/tmp/$(basename "$BACKUP_FILE" | cut -d. -f1)/"
    echo "Restore process succeeded. Exiting."
    exit 0
}
appCerts() {
    configureCerts
}
appHelp() {
    echo "Available commands:"
    echo "> app:help     - Show this help menu and exit"
    echo "> app:version  - Container Zulip server version"
    echo "> app:managepy - Run Zulip's manage.py script (defaults to \"shell\")"
    echo "> app:backup   - Create backups of Zulip instances"
    echo "> app:restore  - Restore backups of Zulip instances"
    echo "> app:certs    - Create self-signed certificates"
    echo "> app:run      - Run the Zulip server"
    echo "> app:init     - Run initial setup of Zulip server"
    echo "> [COMMAND]    - Run given command with arguments in shell"
}
appVersion() {
    local ZULIP_VERSION
    ZULIP_VERSION="$(su zulip -c "cd ~/deployments/current && python3 -c 'import version; print(version.ZULIP_VERSION)'")"
    echo "This container contains Zulip Server $ZULIP_VERSION"
    exit 0
}
# END app functions

case "$1" in
    app:run)
        appRun
        ;;
    app:init)
        appInit
        ;;
    app:managepy)
        shift 1
        appManagePy "$@"
        ;;
    app:backup)
        appBackup
        ;;
    app:restore)
        appRestore
        ;;
    app:certs)
        appCerts
        ;;
    app:help)
        appHelp
        ;;
    app:version)
        appVersion
        ;;
    *)
        exec "$@" || appHelp
        ;;
esac
