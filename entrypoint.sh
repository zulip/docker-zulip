#!/bin/bash

if [ ! -f "$ZULIP_DIR/.database-initialized" ]; then
    su zulip -c "$ZULIP_DIR/deployments/current/scripts/setup/initialize-database"
    su zulip -c "touch $ZULIP_DIR/.database-initialized"
fi
