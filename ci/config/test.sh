#!/bin/bash

set -eux
set -o pipefail

"${docker[@]:?}" exec zulip cat /etc/zulip/zulip.conf >found.conf

diff -u ./ci/config/expected.conf found.conf
