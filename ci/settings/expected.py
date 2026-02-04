AUTHENTICATION_BACKENDS = ('zproject.backends.EmailAuthBackend',)
AUTHENTICATION_BACKENDS += ('zproject.backends.ZulipLDAPAuthBackend',)

# Custom settings start here
from django_auth_ldap.config import GroupOfUniqueNamesType

ALLOWED_HOSTS = ["somehost.example.com", "otherhost.example.com"]
AUTH_LDAP_GROUP_TYPE = GroupOfUniqueNamesType()
AUTH_LDAP_SERVER_URI = 'ldaps://ldap.example.com'
AUTH_LDAP_USER_ATTR_MAP = {"full_name": "cn", "unique_account_id": "dn"}
AUTH_LDAP_USER_SEARCH = LDAPSearch(
    "ou=users,dc=example,dc=com", ldap.SCOPE_SUBTREE, "(sAMAccountName=%(user)s)"
)

EXTERNAL_HOST = '4-you.example.com'
INSTALLATION_NAME = 'We love Apos\'trophes and Back\\slashes'
LDAP_APPEND_DOMAIN = None
LDAP_DEACTIVATE_NON_MATCHING_USERS = True
LDAP_EMAIL_ATTR = None
LDAP_SYNCHRONIZED_GROUPS_BY_REALM = {
  "subdomain1": [
      "group1",
      "group2",
  ]
}

MEMCACHED_LOCATION = 'memcached:11211'
OUTGOING_WEBHOOK_TIMEOUT_SECONDS = 30
RABBITMQ_HOST = 'rabbitmq'
REDIS_HOST = 'redis'
REMOTE_POSTGRES_HOST = 'database'
REMOTE_POSTGRES_SSLMODE = 'prefer'
ZULIP_ADMINISTRATOR = 'admin@example.net'
