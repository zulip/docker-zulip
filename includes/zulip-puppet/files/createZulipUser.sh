#!/bin/bash

"$MANAGE_PY" create_user --this-user-has-accepted-the-tos "$ZULIP_USER_EMAIL" "$ZULIP_USER_FULLNAME" --domain "$ZULIP_USER_DOMAIN" || :
"$MANAGE_PY" knight "$ZULIP_USER_EMAIL" -f
cat | expect <<EOF
#!/usr/bin/expect
spawn "$MANAGE_PY" changepassword "$ZULIP_USER_EMAIL"
expect "Password:"
send_user "$ZULIP_USER_PASSWORD\n"
expect "Password (again):"
send_user "$ZULIP_USER_PASSWORD\n"
EOF
exit 0
