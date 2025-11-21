#!/bin/bash

set -eux
set -o pipefail

url="http://${hostname:?}"

# This is a server error, which describes the need to set LOADBALANCER_IPS
error_page=$(curl -sSi "$url")
echo "$error_page" | grep -Ei "HTTP/\S+ 500"
echo "$error_page" | grep "You have not configured any reverse proxies"
echo "$error_page" | grep "LOADBALANCER_IPS"

# This is a server error, which notes the reverse proxy exists
error_page=$(curl -H "X-Forwarded-For: 1.2.3.4" -sSi "$url")
echo "$error_page" | grep -Ei "HTTP/\S+ 500"
echo "$error_page" | grep "You have not configured any reverse proxies"
echo "$error_page" | grep "reverse proxy headers were detected"
echo "$error_page" | grep "LOADBALANCER_IPS"

# Restart with LOADBALANCER_IPS set
"${docker[@]:?}" -f ci/http-only/with-loadbalancer-ips.yaml up -d --no-build --force-recreate zulip

# Wait for it to come back up
instance=$("${docker[@]}" ps -q zulip)
timeout 300 bash -c \
    "until docker inspect --format '{{.State.Health.Status}}' '$instance' | grep -q healthy; do sleep 5; done"

# This is a server error, which notes the lack of X-Forwarded-Proto
error_page=$(curl -H "X-Forwarded-For: 1.2.3.4" -sSi "$url")
echo "$error_page" | grep -Ei "HTTP/\S+ 500"
echo "$error_page" | grep "You have configured reverse proxies"
echo "$error_page" | grep "X-Forwarded-Proto"

# This is a 404 due to no realm existing
error_page=$(curl -H "X-Forwarded-For: 1.2.3.4" -H "X-Forwarded-Proto: https" -sSi "$url")
echo "$error_page" | grep -Ei "HTTP/\S+ 404"

"${manage[@]:?}" create_realm 'Testing Realm' admin@example.com 'Test Admin' --password very-secret

success=$(curl -H "X-Forwarded-For: 1.2.3.4" -H "X-Forwarded-Proto: https" -sfLSi "$url")
echo "$success" | grep "Testing Realm"

exit 0
