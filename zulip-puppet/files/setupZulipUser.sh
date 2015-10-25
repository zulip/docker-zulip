#!/bin/bash

if [ "$ZULIP_USER_CREATION_ENABLED" != "True" ] || [ "$ZULIP_USER_CREATION_ENABLED" != "true" ]; then
    exit 100
fi
# Zulip user setup
export ZULIP_USER_FULLNAME="${ZULIP_USER_FULLNAME:-Zulip Docker}"
export ZULIP_USER_DOMAIN="${ZULIP_USER_DOMAIN:-$(echo $ZULIP_SETTINGS_EXTERNAL_HOST)}"
export ZULIP_USER_EMAIL="${ZULIP_USER_EMAIL:-}"
ZULIP_USER_PASSWORD="${ZULIP_USER_PASSWORD:-zulip}"
export ZULIP_USER_PASS="${ZULIP_USER_PASS:-$(echo $ZULIP_USER_PASSWORD)}"
unset ZULIP_USER_PASSWORD

if [ -z "$ZULIP_USER_DOMAIN" ] || [ -z "$ZULIP_USER_EMAIL" ]; then
    echo "No zulip user configuration given."
    exit 100
fi
# Doing everything in python, even I never coded in python #YOLO
/home/zulip/deployments/current/manage.py shell <<EOF
from zerver.lib.actions import do_create_user, do_change_is_admin
from zerver.lib.initial_password import initial_password
from zerver.models import Realm, get_realm, UserProfile, email_to_username
from django.db import transaction, IntegrityError
from django.core.management.base import CommandError

try:
    realm = get_realm('$ZULIP_USER_DOMAIN')
except Realm.DoesNotExist:
    raise CommandError("Realm/Domain does not exist.")

try:
    do_create_user('$ZULIP_USER_EMAIL', '$ZULIP_USER_PASS', realm, '$ZULIP_USER_FULLNAME', email_to_username('$ZULIP_USER_EMAIL'))
except:
    pass

email = '$ZULIP_USER_EMAIL'
User = UserProfile.objects.get(email=email)
do_change_is_admin(User, True, 'administer')
User.save()
quit()
EOF
exit 200
