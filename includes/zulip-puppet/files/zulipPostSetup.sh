#!/bin/bash

sleep 5
/home/zulip/deployments/current/manage.py create_user --this-user-has-accepted-the-tos "$ZULIP_USER_EMAIL" "$ZULIP_USER_FULLNAME" --domain "$ZULIP_USER_DOMAIN" || :
/home/zulip/deployments/current/manage.py knight "$ZULIP_USER_EMAIL" -f || :
expect <<'EOF'
spawn /home/zulip/deployments/current/manage.py changepassword $env(ZULIP_USER_EMAIL)
expect "Password: "
send "$env(ZULIP_USER_PASSWORD)"
send "\n"
expect "Password (again): "
send "$env(ZULIP_USER_PASSWORD)"
send "\n"
send "\n"
exit
EOF
