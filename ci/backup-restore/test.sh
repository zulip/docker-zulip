#!/bin/bash

set -eux
set -o pipefail

# In-place restore against an already-configured, running deployment.
# Use case: undo an "oops" -- a bad upgrade, a mistaken migration, or
# anything else where the volume and surrounding services are healthy
# and the only thing wrong is the database state.  See
# ci/backup-restore-volume/ for the disaster-recovery flow.

# One realm, one backup
"${manage[@]:?}" create_realm 'Testing Realm' admin@example.com 'Test Admin' --password very-secret
"${docker[@]:?}" exec zulip /sbin/entrypoint.sh app:backup

if [ "$("${docker[@]}" exec zulip ls /data/backups/ | wc -l)" != "1" ]; then
    exit 1
fi

# Another realm, another backup
"${manage[@]}" create_realm 'Other Realm' admin@example.com 'Test Admin' --password very-secret --string-id other
"${docker[@]}" exec zulip /sbin/entrypoint.sh app:backup

if [ "$("${docker[@]}" exec zulip ls /data/backups/ | wc -l)" != "2" ]; then
    exit 1
fi

"${manage[@]}" list_realms | grep "System bot realm"
"${manage[@]}" list_realms | grep "Testing Realm"
"${manage[@]}" list_realms | grep "Other Realm"

# Restoring the original backup gets us back to one realm
first_backup=$("${docker[@]}" exec zulip ls /data/backups/ | sort | head -n1)
"${docker[@]}" exec zulip /sbin/entrypoint.sh app:restore "$first_backup"

"${manage[@]}" list_realms | grep "System bot realm"
"${manage[@]}" list_realms | grep "Testing Realm"
if "${manage[@]}" list_realms | grep "Other Realm"; then
    exit 1
fi

# `run --rm app:restore` against the running stack should refuse,
# since the live workers are holding persistent DB connections.
if "${docker[@]}" run --rm zulip app:restore "$first_backup"; then
    echo "FAIL: run --rm app:restore did not refuse against live stack"
    exit 1
fi
