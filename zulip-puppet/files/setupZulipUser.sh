#!/bin/bash

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
