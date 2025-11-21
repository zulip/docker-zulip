#!/bin/bash

set -eux
set -o pipefail

url="https://${hostname:?}"

curl --verbose --insecure "${url}"
