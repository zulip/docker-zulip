#!/bin/bash

if [ ! -f "$ZULIP_DIR/.initialized" ]; then
    python "$ZULIP_DIR/provision.py"
    touch "$ZULIP_DIR/.initialized"
fi

tail -f /var/log/zulip/*.log
