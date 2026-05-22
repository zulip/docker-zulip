#!/bin/bash

set -eux
set -o pipefail

# Disaster-recovery restore from a volume tarball onto a clean-slate
# deployment.  Use case: the host died and we're rebuilding from a
# tarball that has the full /data contents and the `app:backup` dump
# file inside it.  Matches docs/how-to/compose-backups.md.
#
# See ci/backup-restore/ for the simpler in-place flow.

# Set up state and take a backup; then create more state that the
# restore should discard.
"${manage[@]:?}" create_realm 'Testing Realm' admin@example.com 'Test Admin' --password very-secret
"${docker[@]:?}" exec zulip /sbin/entrypoint.sh app:backup
"${manage[@]}" create_realm 'Other Realm' admin@example.com 'Test Admin' --password very-secret --string-id other

# Tar the volume contents out.
"${docker[@]}" run --rm -v zulip:/data -v "$(pwd)":/backup zulip \
    tar czf /backup/zulip-volume.tar.gz -C /data .

# Wipe everything, including all named volumes -- the disaster.
"${docker[@]}" down -v

# Restore the volume contents into a fresh `zulip` volume; the
# `run --rm` creates the named volume implicitly.
"${docker[@]}" run --rm --no-deps -v zulip:/data -v "$(pwd)":/backup zulip \
    tar xzf /backup/zulip-volume.tar.gz -C /data

# Restore the database from the dump in the restored `/data/backups/`.
backup_file=$("${docker[@]}" run --rm --no-deps zulip ls /data/backups/ | sort | head -n1)
"${docker[@]}" run --rm zulip app:restore "$backup_file"

"${docker[@]}" up -d --wait

# Verify the data made the round trip: "Testing Realm" is back,
# "Other Realm" (which existed only after the backup) is gone.
"${manage[@]}" list_realms | grep "Testing Realm"
if "${manage[@]}" list_realms | grep "Other Realm"; then
    exit 1
fi
