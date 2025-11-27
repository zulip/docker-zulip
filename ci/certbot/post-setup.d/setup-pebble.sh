#!/bin/bash

# This configures certbot to talk to the Pebble instance we started
echo "server=https://pebble:14000/dir" >>/etc/letsencrypt/cli.ini
echo "no-verify-ssl=true" >>/etc/letsencrypt/cli.ini
