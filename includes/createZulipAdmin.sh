#!/bin/bash

if ([ "$ZULIP_USER_CREATION_ENABLED" == "True" ] && [ "$ZULIP_USER_CREATION_ENABLED" == "true" ]) && ([ -z "$ZULIP_USER_DOMAIN" ] || [ -z "$ZULIP_USER_EMAIL" ] || [ -z "$ZULIP_USER_FULLNAME" ]); then
    echo "No zulip user configuration given."
    exit 1
fi
set +e
# Doing everything in python, even I never coded in python #YOLO
sudo su zulip <<BASH
/home/zulip/deployments/current/manage.py create_realm --string_id="$ZULIP_USER_DOMAIN" --name="$ZULIP_USER_DOMAIN" -d "$ZULIP_USER_DOMAIN"
/home/zulip/deployments/current/manage.py create_user --this-user-has-accepted-the-tos --realm "$ZULIP_USER_DOMAIN" "$ZULIP_USER_EMAIL" "$ZULIP_USER_FULLNAME"
/usr/bin/expect <<EOF
spawn /home/zulip/deployments/current/manage.py changepassword "$ZULIP_USER_EMAIL"
expect -re 'Password:.*'
send "$ZULIP_USER_PASS";
expect -re 'Password (again).*'
send "$ZULIP_USER_PASS
EOF
/home/zulip/deployments/current/manage.py changepassword "$ZULIP_USER_EMAIL"
/home/zulip/deployments/current/manage.py knight "$ZULIP_USER_EMAIL"
BASH
