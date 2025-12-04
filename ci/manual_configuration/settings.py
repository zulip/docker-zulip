# A custom settings.py!
MEMCACHED_LOCATION = "memcached:11211"
RABBITMQ_HOST = "rabbitmq"
RABBITMQ_USER = "zulip"
REDIS_HOST = "redis"
REDIS_PORT = 6379
REMOTE_POSTGRES_HOST = "database"
REMOTE_POSTGRES_PORT = 5432
REMOTE_POSTGRES_SSLMODE = "prefer"

LOCAL_UPLOADS_DIR = "/home/zulip/uploads"

AUTHENTICATION_BACKENDS = ("zproject.backends.EmailAuthBackend",)

EXTERNAL_HOST = "custom-zulip.example.net"
ZULIP_ADMINISTRATOR = "admin@example.net"
