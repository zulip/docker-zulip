#!/bin/bash

# The main `docker compose up` already proved that the bare base
# config starts cleanly with no legacy env vars set. Here we spawn
# ephemeral containers against the same image with one renamed and
# one removed name from the legacy zulip/docker-zulip image, and
# verify the entrypoint sentinel rejects each with a helpful message.

set -eux
set -o pipefail

image="${GITHUB_CI_IMAGE:?error}"

# A renamed setting: error names both the old and new spellings.
if output=$(docker run --rm -e DB_HOST=somevalue "$image" app:help 2>&1); then
    echo "expected DB_HOST to be rejected" >&2
    exit 1
fi
grep -qF "'DB_HOST'" <<<"$output"
grep -qF "SETTING_REMOTE_POSTGRES_HOST" <<<"$output"

# A removed setting: error names the old spelling.
if output=$(docker run --rm -e SPECIAL_SETTING_DETECTION_MODE=True "$image" app:help 2>&1); then
    echo "expected SPECIAL_SETTING_DETECTION_MODE to be rejected" >&2
    exit 1
fi
grep -qF "'SPECIAL_SETTING_DETECTION_MODE'" <<<"$output"
