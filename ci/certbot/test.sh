#!/bin/bash

set -eux
set -o pipefail

getcert() {
    echo | openssl s_client -showcerts -servername zulip.example.net -connect localhost:443 \
        | openssl x509 -text -noout
}
wait_for_log() {
    logline="$1"
    for _ in {1..60}; do
        if "${docker[@]:?}" logs zulip --no-log-prefix --no-color | grep "$logline"; then
            return 0
        fi
        sleep 1
    done

    return 1
}

success=0
for _ in {1..60}; do
    getcert | tee cert.pem

    if grep -E "Issuer: CN\s*=\s*Pebble Intermediate CA" cert.pem; then
        success=1
        break
    fi
    sleep 1
done

if [ "${success}" = "0" ]; then
    echo "Timed out waiting for a Pebble-signed certificate to be served!"
    exit 1
fi

## SMTP should also have the same cert
# We may need to retry a few times, since nginx gets reloaded first,
# and the email server doesn't go hot-reloads.
success=0
for _ in {1..10}; do
    set +o pipefail
    echo | openssl s_client -showcerts -servername zulip.example.net -connect localhost:25 -starttls smtp \
        | openssl x509 -text -noout \
        | tee cert.pem
    set -o pipefail
    if grep -E "Issuer: CN\s*=\s*Pebble Intermediate CA" cert.pem; then
        success=1
        break
    fi
    sleep 1
done

if [ "${success}" = "0" ]; then
    echo "SMTP STARTTLS does not have Pebble-signed certificate!"
    exit 1
fi

## Test renewing -- this should generate and deploy a new certificate
serial=$(grep "Serial Number:" cert.pem)
"${docker[@]:?}" exec zulip /usr/bin/certbot renew --force-renew --no-random-sleep-on-renew
getcert | tee cert.pem
newserial=$(grep "Serial Number:" cert.pem)
if [ "${newserial}" = "${serial}" ]; then
    echo "Failed to renew -- same serial number?"
    exit 1
fi
# For simplicity below, we update $serial
serial="$newserial"

## Restarting the container should not get a new certificate
"${docker[@]}" stop zulip

"${docker[@]}" up zulip --wait
# This will kick off waitAndRunSetupCertbot; we wait for a bit, tailing
# the logs, until we see the "LetsEncrypt cert generated" line that we
# expect at the end of it.
if ! wait_for_log "LetsEncrypt cert generated"; then
    echo "Failed to run Certbot to completion!"
    exit 1
fi
getcert | tee cert.pem
newserial=$(grep "Serial Number:" cert.pem)
if [ "$newserial" != "$serial" ]; then
    echo "Restarting forced a renewal it should not have!"
    exit 1
fi

## Switching to self-signed drops the cert
"${docker[@]}" stop zulip

"${docker[@]}" -f ci/certbot/self-signed.yaml up zulip --wait
logs="$("${docker[@]}" -f ci/certbot/self-signed.yaml logs zulip --no-log-prefix --no-color)"
if echo "$logs" | grep -qEi 'certbot|letsencrypt'; then
    echo "Certbot detected in nominally self-signed configuration!"
    echo "$logs"
    exit 1
fi

getcert | tee cert.pem
if grep -qi pebble cert.pem; then
    echo "Certificate is from Pebble, not self-signed!"
    exit 1
fi

## Even if certbot is renewed in the container, we still serve the configured self-signed cert
"${docker[@]:?}" exec zulip /usr/bin/certbot renew --force-renew --no-random-sleep-on-renew
getcert | tee cert.pem
if grep -qi pebble cert.pem; then
    echo "Certificate is from Pebble, not self-signed!"
    exit 1
fi

## Switching _back_ to certbot still has the same cert, since it's not expired
"${docker[@]}" stop zulip
"${docker[@]}" up zulip --wait
if ! wait_for_log "LetsEncrypt cert generated"; then
    echo "Failed to run certbot codepath in restarted container"
    exit 1
fi
getcert | tee cert.pem
newserial=$(grep "Serial Number:" cert.pem)
if [ "$newserial" != "$serial" ]; then
    echo "Restarting forced a renewal it should not have!"
    exit 1
fi

exit 0
