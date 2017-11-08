#!/bin/bash

sudo -H -u zulip -g zulip bash <<BASH
/home/zulip/deployments/current/manage.py generate_realm_creation_link
BASH
