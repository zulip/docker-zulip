#!/bin/bash
#
# Functional test for the Zulip Helm chart.
#
# Usage: test.sh <pod-name> <port>
#
# Exercises the Zulip API after a Helm install to verify the deployment
# actually works, not just that pods started.
#
# Because we access Zulip through kubectl port-forward on localhost, but
# Zulip expects its configured SETTING_EXTERNAL_HOST, we use curl's
# --resolve flag to send the correct Host header while connecting to
# localhost.

set -eux
set -o pipefail

pod="${1:?Usage: test.sh <pod-name> <port>}"
port="${2:?Usage: test.sh <pod-name> <port>}"

manage=(kubectl exec "$pod" -c zulip --
    runuser -u zulip --
    /home/zulip/deployments/current/manage.py)

# Resolve zulip.example.net to localhost so curl sends the right Host
# header.  This must match SETTING_EXTERNAL_HOST in simple-values.yaml.
host="zulip.example.net"
url="http://${host}:${port}"
curl_opts=(--resolve "${host}:${port}:127.0.0.1")

# shellcheck source=SCRIPTDIR/../../../ci/test-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../../ci/test-common.sh"

exit 0
