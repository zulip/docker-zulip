#!/bin/bash

set -eux
set -o pipefail

"${docker[@]:?}" exec zulip cat /etc/zulip/settings.py \
    | grep -A100 'AUTHENTICATION_BACKENDS =' >found.py

diff -u ./ci/settings/expected.py found.py
