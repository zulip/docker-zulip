#!/bin/bash

if [ -f "" ]; then
    su zulip -c "$ZULIP_DIR/deployments/current/scripts/setup/initialize-database"
fi
