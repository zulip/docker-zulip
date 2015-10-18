#!/bin/bash

command -v openssl >/dev/null 2>&1 || { echo >&2 "openssl package not installed.  Aborting."; exit 1; }

openssl genrsa -des3 -passout pass:x -out server.pass.key 4096
openssl rsa -passin pass:x -in server.pass.key -out zulip.key
rm -f server.pass.key
openssl req -new -key zulip.key -out server.csr
openssl x509 -req -days 365 -in server.csr -signkey zulip.key -out zulip.combined-chain.crt
rm -f server.csr
echo "Copy the following files to the docker-zulip data folder:"
echo "* zulip.key"
echo "* zulip.combined-chain.crt"
