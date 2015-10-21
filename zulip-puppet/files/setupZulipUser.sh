#!/bin/bash

/home/zulip/deployments/current/manage.py create_user --this-user-has-accepted-the-tos "$ZULIP_USER_EMAIL" "$ZULIP_USER_FULLNAME" --domain "$ZULIP_USER_DOMAIN" || :
/home/zulip/deployments/current/manage.py knight "$ZULIP_USER_EMAIL" -f || :
/home/zulip/deployments/current/manage.py shell <<EOF
from zerver.decorator import get_user_profile_by_email
User = get_user_profile_by_email('atrost@zerbytes.net')
User.set_password('$ZULIP_USER_PASS')
User.save()
EOF
exit 200
