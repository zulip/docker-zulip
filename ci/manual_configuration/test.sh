#!/bin/bash

set -eux
set -o pipefail

# Initial MANUAL_CONFIGURATION gets a bootstrapping warning
logs() {
    output="$("${docker[@]:?}" logs zulip --no-log-prefix --no-color)"
    echo "$output"
}
logs | grep "Bootstrapping initial MANUAL_CONFIGURATION"
if [ "$("${docker[@]}" exec zulip readlink /etc/zulip/zulip-secrets.conf)" != "/data/zulip-secrets.conf" ]; then
    exit 1
fi
get_current_secret() {
    "${docker[@]}" exec zulip crudini --get /etc/zulip/zulip-secrets.conf secrets shared_secret
}
shared_secret="$(get_current_secret)"

"${docker[@]}" exec zulip find /etc/zulip /data/ -ls

# Restarting warns about the SETTING_ values; it preserves the same secrets
"${docker[@]}" restart zulip
"${docker[@]}" up zulip --wait
logs | grep "SETTING_ environment variables detected"
if [ "$shared_secret" != "$(get_current_secret)" ]; then
    exit 1
fi

# Recreate it with a bind mounted settings.py
with() {
    echo "--file=./ci/manual_configuration/$1.yaml"
}
"${docker[@]}" "$(with no-envs)" up zulip --wait
"${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "A custom settings.py"
if logs | grep "SETTING_ environment variables detected"; then
    exit 1
fi
if [ "$shared_secret" != "$(get_current_secret)" ]; then
    exit 1
fi

# Having a bind mounted settings.py and a SETTING_ value shows a warning, and the value is ignored
"${docker[@]}" "$(with no-envs)" "$(with new-hostname)" up zulip --wait
logs | grep "SETTING_ environment variables detected"
if "${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "other.example.net"; then
    exit 1
fi

# Move to a LINK_SETTINGS_TO_DATA deployment; this should re-configure
# a new instance, reading the SETTING_ values to bootstrap, and store
# the config in /data/etc-zulip/.  Existing secrets will get moved
# into there.
"${docker[@]}" "$(with link-settings)" up zulip --wait
"${docker[@]}" exec zulip readlink /etc/zulip | grep "/data/etc-zulip"
logs | grep "Bootstrapping initial MANUAL_CONFIGURATION"
if [ "$shared_secret" != "$(get_current_secret)" ]; then
    exit 1
fi

# Re-creating it with a SETTING_ value shows a warning, and the value is ignored
"${docker[@]}" "$(with link-settings)" "$(with new-hostname)" up zulip --wait
logs | grep "SETTING_ environment variables detected"
if "${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "other.example.net"; then
    exit 1
fi

# Simulating an old-style settings/etc-zulip migration
"${docker[@]}" down zulip
"${docker[@]}" run --rm zulip mkdir -p /data/settings
"${docker[@]}" run --rm zulip mv /data/etc-zulip /data/settings/etc-zulip
"${docker[@]}" "$(with link-settings)" up zulip --wait
logs | grep "Migrating old /data/settings/etc-zulip"
"${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "zulip.example.net"

# Delete the volume and start from scratch with both
# LINK_SETTINGS_TO_DATA and MANUAL_CONFIGURATION; the secrets will be
# different, except the Docker secrets will set up inter-service auth
# correctly.
"${docker[@]}" down zulip --volumes
"${docker[@]}" "$(with link-settings)" up zulip --wait
logs | grep "Bootstrapping initial MANUAL_CONFIGURATION"
"${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "zulip.example.net"
if [ "$shared_secret" == "$(get_current_secret)" ]; then
    exit 1
fi
shared_secret="$(get_current_secret)"

# Restarting with changed settings will show warnings about SETTING_ variables, but have the old state
"${docker[@]}" "$(with link-settings)" "$(with new-hostname)" up zulip --wait
logs | grep "SETTING_ environment variables detected"
"${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "zulip.example.net"
if "${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "other.example.net"; then
    exit 1
fi

# Break settings.py
"${docker[@]}" exec zulip perl -ni -e 'print unless /EXTERNAL_HOST/' /etc/zulip/settings.py
"${docker[@]}" down zulip
if "${docker[@]}" "$(with link-settings)" up zulip --wait; then
    exit 1
fi
logs | grep "ImportError: cannot import name 'EXTERNAL_HOST'"

# Break zulip.conf
"${docker[@]}" run --rm zulip truncate -s 0 /data/etc-zulip/zulip.conf
if "${docker[@]}" "$(with link-settings)" up zulip --wait; then
    exit 1
fi
logs | grep "ERROR: /data/etc-zulip/zulip.conf is empty"

# Swapping to LINK_SETTINGS_TO_DATA=False will still use the old
# secrets (though in /data/etc-zulip/zulip-secrets.conf instead of
# /data/zulip-secrets.conf)
"${docker[@]}" "$(with no-envs)" up zulip --wait
"${docker[@]}" exec zulip cat /etc/zulip/settings.py | grep "A custom settings.py"
"${docker[@]}" exec zulip readlink /etc/zulip/zulip-secrets.conf | grep "/data/etc-zulip/zulip-secrets.conf"
if "${docker[@]}" exec zulip [ -f /data/zulip-secrets.conf ]; then
    exit 1
fi
if [ "$shared_secret" != "$(get_current_secret)" ]; then
    exit 1
fi

exit 0
