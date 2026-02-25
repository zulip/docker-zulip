#!/bin/bash

set -eux
set -o pipefail

url="https://${hostname:?}"
curl_opts=(--insecure)

# HTTP redirects to HTTPS
curl -si "http://$hostname" 2>&1 | grep -i "location: $url"

# Check the rest of the basic end-to-end tests
# shellcheck source=SCRIPTDIR/../test-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../test-common.sh"

exit 0
